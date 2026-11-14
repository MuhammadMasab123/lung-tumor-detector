import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/doctor_service.dart';
import '../theme.dart';

/// Doctor Finder — same logic as the web DoctorFinder.jsx.
/// Device location + OpenStreetMap Overpass API, deterministic slots.
class DoctorFinderScreen extends StatefulWidget {
  final bool urgent;

  const DoctorFinderScreen({super.key, this.urgent = false});

  @override
  State<DoctorFinderScreen> createState() => _DoctorFinderScreenState();
}

class _DoctorFinderScreenState extends State<DoctorFinderScreen> {
  // idle | locating | loading | done | error
  String _state = 'idle';
  List<Facility> _facilities = [];
  String _error = '';
  int _radiusKm = 10;
  String _filter = 'all';
  double? _lat;
  double? _lon;

  static const List<int> _radiusOptions = [3, 5, 10, 20];

  String _radiusLabel(int km) {
    switch (km) {
      case 3:
        return '3 km — Walking distance';
      case 5:
        return '5 km — Short drive';
      case 10:
        return '10 km — City area';
      case 20:
        return '20 km — Wider region';
      default:
        return '$km km';
    }
  }

  List<Facility> get _filtered {
    if (_filter == 'all') return _facilities;
    return _facilities.where((f) => f.amenity == _filter).toList();
  }

  int _count(String amenity) =>
      _facilities.where((f) => f.amenity == amenity).length;

  Future<void> _locate() async {
    setState(() {
      _state = 'locating';
      _error = '';
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _state = 'error';
          _error =
              'Location access denied. Allow location in your device settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _lat = position.latitude;
      _lon = position.longitude;

      setState(() => _state = 'loading');
      final facilities =
          await fetchNearbyFacilities(_lat!, _lon!, _radiusKm);
      setState(() {
        _facilities = facilities;
        _state = 'done';
      });
    } catch (e) {
      setState(() {
        _state = 'error';
        _error = e.toString().contains('timeout')
            ? 'Location request timed out.'
            : 'Could not fetch nearby facilities. Check your connection.';
      });
    }
  }

  void _retry() {
    setState(() {
      _facilities = [];
      _error = '';
      _state = 'idle';
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find Nearby Doctor', style: TextStyle(fontSize: 18)),
            Text(
              'Hospitals, clinics & specialists near you',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Urgent banner
            if (widget.urgent)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Urgent: Specialist Consultation Recommended',
                            style: TextStyle(
                              color: AppColors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your scan result indicates potential lung cancer. Find and contact a pulmonologist or oncologist as soon as possible.',
                            style: TextStyle(
                              color: Color(0x59FFFFFF),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Search settings card
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Settings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SEARCH RADIUS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.faint,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _radiusKm,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _radiusOptions
                        .map(
                          (km) => DropdownMenuItem(
                            value: km,
                            child: Text(_radiusLabel(km)),
                          ),
                        )
                        .toList(),
                    onChanged: (_state == 'loading' || _state == 'locating')
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _radiusKm = value);
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  if (_state == 'idle' || _state == 'error') ...[
                    ElevatedButton.icon(
                      onPressed: _locate,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Use My Location to Find Doctors'),
                    ),
                    if (_state == 'error') ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _error,
                          style: const TextStyle(
                            color: AppColors.redDark,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(
                        _lat != null
                            ? 'https://www.google.com/maps/search/lung+specialist+near+me/@$_lat,$_lon,13z'
                            : 'https://www.google.com/maps/search/pulmonologist+near+me',
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Or search on Google Maps instead'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                  if (_state == 'locating' || _state == 'loading')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.mint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _state == 'locating'
                                ? 'Getting your location…'
                                : 'Finding facilities within $_radiusKm km…',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _state == 'locating'
                                ? 'Please allow location access when prompted'
                                : 'Powered by OpenStreetMap',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Results
            if (_state == 'done') ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'FILTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.faint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'All (${_facilities.length})',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    _FilterChip(
                      label: 'Hospitals (${_count('hospital')})',
                      selected: _filter == 'hospital',
                      onTap: () => setState(() => _filter = 'hospital'),
                    ),
                    _FilterChip(
                      label: 'Clinics (${_count('clinic')})',
                      selected: _filter == 'clinic',
                      onTap: () => setState(() => _filter = 'clinic'),
                    ),
                    _FilterChip(
                      label: 'Doctors (${_count('doctors')})',
                      selected: _filter == 'doctors',
                      onTap: () => setState(() => _filter = 'doctors'),
                    ),
                    TextButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('New Search',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Found ${_filtered.length} facilities within $_radiusKm km — sorted by distance',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              if (_filtered.isEmpty)
                const SectionCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No facilities found in this category.\nTry increasing the search radius.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                ..._filtered.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FacilityCard(
                      facility: f,
                      urgent: widget.urgent,
                      onOpenUrl: _openUrl,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _openUrl(
                  _lat != null
                      ? 'https://www.google.com/maps/search/lung+specialist+near+me/@$_lat,$_lon,13z'
                      : 'https://www.google.com/maps/search/pulmonologist+near+me',
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View all specialists on Google Maps'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.mintDim,
        labelStyle: TextStyle(
          color: selected ? AppColors.mintDark : AppColors.muted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected ? AppColors.mint : AppColors.stone,
        ),
        backgroundColor: Colors.white,
        showCheckmark: false,
      ),
    );
  }
}

class _FacilityCard extends StatefulWidget {
  final Facility facility;
  final bool urgent;
  final Future<void> Function(String url) onOpenUrl;

  const _FacilityCard({
    required this.facility,
    required this.urgent,
    required this.onOpenUrl,
  });

  @override
  State<_FacilityCard> createState() => _FacilityCardState();
}

class _FacilityCardState extends State<_FacilityCard> {
  int? _selectedSlot;

  Color _chipColor() {
    switch (widget.facility.amenity) {
      case 'hospital':
        return AppColors.redDark;
      case 'clinic':
        return AppColors.blue;
      case 'doctors':
        return AppColors.mintDark;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    final slots = generateSlots(f.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.urgent
              ? AppColors.red.withValues(alpha: 0.25)
              : AppColors.stone,
        ),
        boxShadow: widget.urgent
            ? [
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.05),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _chipColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _chipColor().withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            f.typeLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _chipColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.stone),
                          ),
                          child: Text(
                            f.distanceLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: f.distanceKm < 2
                                  ? AppColors.mintDark
                                  : f.distanceKm < 5
                                      ? AppColors.blue
                                      : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (f.address != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    f.address!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.ink2,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (f.phone != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => widget.onOpenUrl('tel:${f.phone}'),
                  child: Text(
                    f.phone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          const Row(
            children: [
              Text(
                'Available slots',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '(confirm by phone)',
                style: TextStyle(fontSize: 11, color: AppColors.faint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: slots.asMap().entries.map((entry) {
              final i = entry.key;
              final slot = entry.value;
              final selected = _selectedSlot == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.mint : const Color(0xFFF0FDF9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${slot.day} · ${slot.time}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.navy : AppColors.mintDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedSlot != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                '✓ ${slots[_selectedSlot!].day} at ${slots[_selectedSlot!].time} — call the facility to confirm.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onOpenUrl(f.directionsUrl),
                  icon: const Icon(Icons.navigation_outlined, size: 15),
                  label: const Text('Directions', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.mint,
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onOpenUrl(f.mapsUrl),
                  icon: const Icon(Icons.search, size: 15),
                  label: const Text('View on Map', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
