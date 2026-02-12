import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  final String _cloudName = 'dex9qoxcc';
  final String _uploadPreset = 'Presets';

  Future<String> uploadImage({
    required Uint8List bytes,
    required String folder,
    String? fileName,
  }) async {
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName ?? 'upload.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    final decoded = json.decode(responseBody);
    final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final error = map?['error'];
      final errorMap = error is Map ? Map<String, dynamic>.from(error) : null;
      final errorMessage = errorMap != null
          ? (errorMap['message']?.toString() ?? 'Error subiendo a Cloudinary')
          : 'Error subiendo a Cloudinary';
      throw Exception(errorMessage);
    }

    final secureUrl = map?['secure_url']?.toString() ?? '';
    if (secureUrl.trim().isEmpty) {
      throw Exception('Cloudinary no devolvió secure_url');
    }

    return secureUrl;
  }
}
