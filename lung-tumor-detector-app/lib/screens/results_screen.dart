import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../theme.dart';
import 'doctor_finder_screen.dart';

/// Results screen — same content as the web Results.jsx.
class ResultsScreen extends StatelessWidget {
  final ScanResult result;

  const ResultsScreen({super.key, required this.result});

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  Widget _scanPane({
    required String label,
    required Widget child,
    required String hint,
    Color? labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: labelColor ?? Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hint,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final verdictColor = AppColors.verdictColor(result.prediction);
    final verdictBg = AppColors.verdictBg(result.prediction);

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Scan images ──
            _scanPane(
              label: 'ORIGINAL SCAN',
              hint: 'Uploaded chest X-ray image',
              child: result.originalImage != null
                  ? Image.memory(
                      base64Decode(result.originalImage!),
                      fit: BoxFit.contain,
                    )
                  : const _EmptyPane(text: 'No image'),
            ),
            const SizedBox(height: 16),
            _scanPane(
              label: 'GRAD-CAM HEATMAP',
              hint: result.heatmapImage != null
                  ? 'Blue area represents AI-flagged high-risk regions'
                  : 'Heatmap not generated',
              labelColor: result.heatmapImage != null
                  ? Colors.red.withValues(alpha: 0.7)
                  : null,
              child: result.heatmapImage != null
                  ? Image.memory(
                      base64Decode(result.heatmapImage!),
                      fit: BoxFit.contain,
                    )
                  : _EmptyPane(text: result.heatmapError ?? 'Unavailable'),
            ),
            const SizedBox(height: 16),

            // ── Verdict box ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: verdictBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: verdictColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: verdictColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      result.isCancerous
                          ? Icons.warning_amber_rounded
                          : result.isUncertain
                              ? Icons.help_outline
                              : Icons.check,
                      color: verdictColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.prediction,
                          style: TextStyle(
                            color: verdictColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: [
                            Text(
                              'Confidence: ${result.confidencePct}%',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.ink2,
                              ),
                            ),
                            Text(
                              '· ${result.riskLevel} Risk',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.riskColor(result.riskLevel),
                              ),
                            ),
                            if (result.lungConfidence != null)
                              Text(
                                '· Lung gate: ${result.lungConfidence!.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.ink2,
                                ),
                              ),
                          ],
                        ),
                        if (result.isUncertain)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Model could not make a confident determination. Please consult a radiologist.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Urgent doctor CTA (cancerous only) ──
            if (result.isCancerous)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
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
                            'Specialist consultation recommended',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Find a pulmonologist or oncologist near you with available slots.',
                            style: TextStyle(
                              color: Color(0x59FFFFFF),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DoctorFinderScreen(urgent: true),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Find Doctor', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            if (result.isCancerous) const SizedBox(height: 16),

            // ── Metric grid ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                _MetricTile(
                  label: 'Prediction',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: verdictBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: verdictColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      result.prediction,
                      style: TextStyle(
                        color: verdictColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _MetricTile(
                  label: 'Risk Level',
                  child: Text(
                    result.riskLevel,
                    style: TextStyle(
                      color: AppColors.riskColor(result.riskLevel),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _MetricTile(
                  label: 'Cancer Probability',
                  child: Text(
                    '${result.cancerProbability.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _MetricTile(
                  label: 'Status',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mintDim,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      result.status == 'success' ? 'Complete' : result.status,
                      style: const TextStyle(
                        color: AppColors.mintDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Confidence bar ──
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Confidence Score',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink2,
                        ),
                      ),
                      Text(
                        '${result.confidencePct}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: verdictColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: result.confidence.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: AppColors.stone,
                      valueColor: AlwaysStoppedAnimation<Color>(verdictColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Medical advice ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.isCancerous
                    ? const Color(0xFFFFFBF0)
                    : AppColors.mintDim.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: result.isCancerous
                      ? const Color(0xFFFDE68A)
                      : AppColors.mint.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: 16,
                        color: result.isCancerous
                            ? const Color(0xFF92400E)
                            : AppColors.mintDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Medical Recommendations',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: result.isCancerous
                              ? const Color(0xFF92400E)
                              : AppColors.mintDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (result.recommendation != null) ...[
                    Text(
                      result.recommendation!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: result.isCancerous
                            ? const Color(0xFF78350F)
                            : AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Urgency: ${result.urgency ?? '—'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: result.isCancerous
                            ? const Color(0xFF78350F)
                            : AppColors.ink2,
                      ),
                    ),
                  ] else if (result.isCancerous)
                    const _AdviceList(items: [
                      'Seek immediate consultation with an oncologist or pulmonologist',
                      'Schedule additional imaging (CT scan, PET scan)',
                      'Consider biopsy for definitive diagnosis',
                      'Discuss treatment options with your healthcare team',
                    ])
                  else
                    const _AdviceList(items: [
                      'Continue regular health screenings',
                      'Maintain a healthy lifestyle',
                      'Monitor for any new respiratory symptoms',
                      'Follow-up screening per medical guidelines',
                    ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tech details ──
            SectionCard(
              child: Column(
                children: [
                  _TechRow(label: 'Model', value: 'ResNet50 Transfer Learning'),
                  const Divider(height: 20),
                  const _TechRow(label: 'Input', value: '224 × 224 px'),
                  const Divider(height: 20),
                  _TechRow(label: 'Generated', value: _formatDate(result.date)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Disclaimer ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.stone),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink2,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Important: ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                'This AI tool is a screening aid only and does not replace professional medical diagnosis. All results must be reviewed by a qualified healthcare professional before any clinical decision is made.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  final String text;

  const _EmptyPane({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported_outlined,
              size: 32, color: Colors.white54),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final Widget child;

  const _MetricTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.faint,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _AdviceList extends StatelessWidget {
  final List<String> items;

  const _AdviceList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TechRow extends StatelessWidget {
  final String label;
  final String value;

  const _TechRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.faint,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.ink2),
          ),
        ),
      ],
    );
  }
}
