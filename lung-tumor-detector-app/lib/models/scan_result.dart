import 'dart:convert';

/// One scan result from the backend POST /predict endpoint.
/// Field names match the FastAPI response exactly.
class ScanResult {
  final String prediction; // "Cancerous" | "Non-Cancerous" | "Uncertain"
  final double confidence; // 0..1
  final double cancerProbability; // percent, e.g. 87.42
  final double nonCancerProbability; // percent
  final double? lungConfidence; // percent
  final String riskLevel; // High | Moderate | Low | Very Low | Indeterminate
  final String status;
  final String? recommendation;
  final String? urgency;
  final String? originalImage; // base64 PNG
  final String? heatmapImage; // base64 PNG
  final String? heatmapError;
  final String fileName;
  final DateTime date;

  ScanResult({
    required this.prediction,
    required this.confidence,
    required this.cancerProbability,
    required this.nonCancerProbability,
    this.lungConfidence,
    required this.riskLevel,
    required this.status,
    this.recommendation,
    this.urgency,
    this.originalImage,
    this.heatmapImage,
    this.heatmapError,
    required this.fileName,
    required this.date,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json, String fileName) {
    final advice = json['medical_advice'] as Map<String, dynamic>?;
    return ScanResult(
      prediction: json['prediction'] as String? ?? 'Uncertain',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      cancerProbability: (json['cancer_probability'] as num?)?.toDouble() ?? 0,
      nonCancerProbability:
          (json['non_cancer_probability'] as num?)?.toDouble() ?? 0,
      lungConfidence: (json['lung_confidence'] as num?)?.toDouble(),
      riskLevel: json['risk_level'] as String? ?? 'Indeterminate',
      status: json['status'] as String? ?? 'success',
      recommendation: advice?['recommendation'] as String?,
      urgency: advice?['urgency'] as String?,
      originalImage: json['original_image'] as String?,
      heatmapImage: json['heatmap_image'] as String?,
      heatmapError: json['heatmap_error'] as String?,
      fileName: fileName,
      date: DateTime.now(),
    );
  }

  bool get isCancerous => prediction == 'Cancerous';
  bool get isUncertain => prediction == 'Uncertain';

  String get confidencePct => (confidence * 100).toStringAsFixed(1);

  /// Full JSON for saving to history. Images are NOT stored (too big for
  /// shared_preferences) — history keeps the numbers, like the web app.
  Map<String, dynamic> toHistoryJson() {
    return {
      'id': date.millisecondsSinceEpoch,
      'date': date.toIso8601String(),
      'fileName': fileName,
      'prediction': prediction,
      'confidence': confidence,
      'cancer_probability': cancerProbability,
      'risk_level': riskLevel,
    };
  }

  factory ScanResult.fromHistoryJson(Map<String, dynamic> json) {
    return ScanResult(
      prediction: json['prediction'] as String? ?? 'Uncertain',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      cancerProbability: (json['cancer_probability'] as num?)?.toDouble() ?? 0,
      nonCancerProbability: 0,
      riskLevel: json['risk_level'] as String? ?? 'Indeterminate',
      status: 'Complete',
      fileName: json['fileName'] as String? ?? 'Unknown',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static String encodeHistory(List<ScanResult> list) {
    return jsonEncode(list.map((r) => r.toHistoryJson()).toList());
  }

  static List<ScanResult> decodeHistory(String raw) {
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => ScanResult.fromHistoryJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
