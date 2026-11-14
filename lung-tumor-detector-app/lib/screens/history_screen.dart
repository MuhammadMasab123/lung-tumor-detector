import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../services/history_service.dart';
import '../theme.dart';
import 'results_screen.dart';

/// Scan History — same content as the web ScanHistoryPage.jsx.
/// Stats row, filter chips, list of past scans. Tap an entry to view it again.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _history = [];
  String _filter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await HistoryService.getHistory();
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  List<ScanResult> get _filtered {
    if (_filter == 'all') return _history;
    return _history.where((h) => h.prediction == _filter).toList();
  }

  int _count(String prediction) =>
      _history.where((h) => h.prediction == prediction).length;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year} · $hour:$minute';
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This will delete all saved scan records from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HistoryService.clearAll();
      _load();
    }
  }

  void _openEntry(ScanResult entry) {
    // History stores the numbers only (no images) — show the saved result.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(result: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.redDark),
              tooltip: 'Clear all',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.history,
                          size: 56,
                          color: AppColors.faint,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No scan history yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload and analyse a chest X-ray on the Home tab to see results here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats row
                      Row(
                        children: [
                          _StatCard(
                            label: 'Total Scans',
                            value: _history.length,
                            color: AppColors.blue,
                            bg: const Color(0xFFEFF6FF),
                          ),
                          _StatCard(
                            label: 'Cancerous',
                            value: _count('Cancerous'),
                            color: AppColors.redDark,
                            bg: const Color(0xFFFEF2F2),
                          ),
                          _StatCard(
                            label: 'Non-Cancerous',
                            value: _count('Non-Cancerous'),
                            color: const Color(0xFF16A34A),
                            bg: const Color(0xFFF0FDF4),
                          ),
                          _StatCard(
                            label: 'Uncertain',
                            value: _count('Uncertain'),
                            color: AppColors.amberDark,
                            bg: const Color(0xFFFFFBEB),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All (${_history.length})',
                              selected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                            _FilterChip(
                              label: 'Cancerous (${_count('Cancerous')})',
                              selected: _filter == 'Cancerous',
                              onTap: () =>
                                  setState(() => _filter = 'Cancerous'),
                            ),
                            _FilterChip(
                              label:
                                  'Non-Cancerous (${_count('Non-Cancerous')})',
                              selected: _filter == 'Non-Cancerous',
                              onTap: () =>
                                  setState(() => _filter = 'Non-Cancerous'),
                            ),
                            _FilterChip(
                              label: 'Uncertain (${_count('Uncertain')})',
                              selected: _filter == 'Uncertain',
                              onTap: () =>
                                  setState(() => _filter = 'Uncertain'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No scans match this filter.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        )
                      else
                        ..._filtered.map((entry) {
                          final color =
                              AppColors.verdictColor(entry.prediction);
                          return Dismissible(
                            key: ValueKey(
                              entry.date.millisecondsSinceEpoch,
                            ),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) async {
                              await HistoryService.deleteScan(
                                entry.date.millisecondsSinceEpoch,
                              );
                              _load();
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _openEntry(entry),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.canvas,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.muted,
                                  ),
                                ),
                                title: Text(
                                  entry.fileName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(entry.date),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            child: LinearProgressIndicator(
                                              value: entry.confidence
                                                  .clamp(0, 1),
                                              minHeight: 5,
                                              backgroundColor: AppColors.stone,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                color,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${entry.confidencePct}%',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.verdictBg(
                                          entry.prediction,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        entry.prediction,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.riskLevel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.riskColor(
                                          entry.riskLevel,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.stone),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
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
      padding: const EdgeInsets.only(right: 8),
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
