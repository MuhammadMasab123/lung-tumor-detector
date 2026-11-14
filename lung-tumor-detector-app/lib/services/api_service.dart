import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/scan_result.dart';
import 'session_service.dart';

/// Talks to the FastAPI backend from the original LungTumorDetector repo.
/// Endpoints: GET /health, POST /predict (multipart, field "file").
class ApiService {
  /// Readable error message for the user.
  static String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is Map<String, dynamic>) {
          // e.g. {"error": "This does not appear to be a lung scan.",
          //      "suggestion": "Please upload a valid chest X-ray."}
          final error = detail['error'] as String?;
          final suggestion = detail['suggestion'] as String?;
          if (error != null && suggestion != null) {
            return '$error\n$suggestion';
          }
          return error ?? suggestion ?? 'Image validation failed.';
        }
        if (detail is String) return detail;
      }
    } catch (_) {
      // fall through to the generic message
    }
    return 'Request failed (${response.statusCode}). Please try again.';
  }

  /// GET /health — returns {"status", "model_status", "firebase_status"}.
  static Future<Map<String, dynamic>> getHealth() async {
    final baseUrl = await SessionService.apiBaseUrl;
    final response = await http
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /predict — uploads a chest X-ray / CT scan image.
  /// Takes raw bytes (not a File) so it works on Flutter Web too.
  /// The backend only enforces a Firebase token when Firebase is configured
  /// server-side; otherwise it works without one.
  static Future<ScanResult> predictScan(
      Uint8List imageBytes, String fileName) async {
    final baseUrl = await SessionService.apiBaseUrl;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
    );

    final streamed = await request.send().timeout(
          const Duration(seconds: 120),
        );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ScanResult.fromJson(json, fileName);
  }
}
