import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Unsigned uploads to Cloudinary (preset must allow unsigned in dashboard).
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  static const cloudName = 'dbyblpcow';
  static const uploadPreset = 'AeroFit';

  static final _uploadUri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  final http.Client _client;

  /// Uploads image bytes from [file] (image_picker) and returns the secure URL.
  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'exercise.jpg',
        ),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary response missing secure_url');
    }
    return url;
  }
}
