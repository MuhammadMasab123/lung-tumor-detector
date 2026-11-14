import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Doctor finder — same logic as the web DoctorFinder.jsx.
/// Uses the device location + OpenStreetMap Overpass API.
class Facility {
  final int id;
  final String name;
  final String amenity; // hospital | clinic | doctors | health_post
  final String? phone;
  final String? address;
  final double lat;
  final double lon;
  final double distanceKm;

  Facility({
    required this.id,
    required this.name,
    required this.amenity,
    this.phone,
    this.address,
    required this.lat,
    required this.lon,
    required this.distanceKm,
  });

  String get distanceLabel {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get typeLabel {
    switch (amenity) {
      case 'hospital':
        return 'Hospital';
      case 'clinic':
        return 'Clinic';
      case 'doctors':
        return 'Doctor';
      case 'health_post':
        return 'Health Post';
      default:
        return 'Medical';
    }
  }

  String get directionsUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';

  String get mapsUrl =>
      'https://www.google.com/maps/search/${Uri.encodeComponent(name)}/@$lat,$lon,16z';
}

class Slot {
  final String day; // Today | Tomorrow | "Mon 12 Nov"
  final String time;

  Slot({required this.day, required this.time});
}

/// Same slot times as the web app.
const List<String> slotTimes = [
  '9:00 AM',
  '9:30 AM',
  '10:00 AM',
  '11:00 AM',
  '11:30 AM',
  '1:00 PM',
  '2:00 PM',
  '2:30 PM',
  '3:30 PM',
  '4:00 PM',
  '5:00 PM',
];

/// Deterministic slots from the facility id — same seed logic as the web app,
/// so the same facility always shows the same slots.
List<Slot> generateSlots(int facilityId) {
  final seed = facilityId.abs() % 97;
  final slots = <Slot>[];
  final today = DateTime.now();
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  for (var day = 0; day < 3; day++) {
    final d = today.add(Duration(days: day));
    final label = day == 0
        ? 'Today'
        : day == 1
            ? 'Tomorrow'
            : '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
    final count = 1 + ((seed + day) % 3);
    for (var s = 0; s < count; s++) {
      slots.add(Slot(
        day: label,
        time: slotTimes[(seed + day * 4 + s) % slotTimes.length],
      ));
    }
  }
  return slots;
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = pow(sin(dLat / 2), 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * pow(sin(dLon / 2), 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// POST to Overpass, same query as the web app. Returns up to 20 facilities
/// sorted by distance.
Future<List<Facility>> fetchNearbyFacilities(
    double lat, double lon, int radiusKm) async {
  final radiusM = radiusKm * 1000;
  final query =
      '[out:json][timeout:30];(node["amenity"~"hospital|clinic|doctors|health_post"](around:$radiusM,$lat,$lon);way["amenity"~"hospital|clinic|doctors|health_post"](around:$radiusM,$lat,$lon);relation["amenity"~"hospital|clinic|doctors|health_post"](around:$radiusM,$lat,$lon););out body center;';

  final response = await http
      .post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      )
      .timeout(const Duration(seconds: 40));

  if (response.statusCode != 200) {
    throw Exception('Could not fetch nearby facilities. Check your connection.');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final elements = (data['elements'] as List?) ?? [];
  final facilities = <Facility>[];

  for (final el in elements) {
    final map = el as Map<String, dynamic>;
    final elLat = (map['lat'] as num?)?.toDouble() ??
        ((map['center'] as Map?)?['lat'] as num?)?.toDouble();
    final elLon = (map['lon'] as num?)?.toDouble() ??
        ((map['center'] as Map?)?['lon'] as num?)?.toDouble();
    if (elLat == null || elLon == null) continue;

    final tags = (map['tags'] as Map<String, dynamic>?) ?? {};
    final addressParts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:city'],
    ].whereType<String>().where((s) => s.isNotEmpty).toList();

    facilities.add(Facility(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: tags['name'] as String? ?? 'Unnamed Facility',
      amenity: tags['amenity'] as String? ?? 'health_post',
      phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
      address: addressParts.isEmpty ? null : addressParts.join(', '),
      lat: elLat,
      lon: elLon,
      distanceKm: _haversineKm(lat, lon, elLat, elLon),
    ));
  }

  facilities.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return facilities.take(20).toList();
}
