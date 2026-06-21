import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String _cloudName = 'dsbfuphyp';
  final String _uploadPreset = 'avatars_preset';

  Future<String> uploadPhoto({
    File? file,
    Uint8List? bytes,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    try {
      if (kIsWeb && bytes != null) {
        final base64Image = base64Encode(bytes);
        final response = await http.post(
          uri,
          body: {
            'file': 'data:image/jpeg;base64,$base64Image',
            'upload_preset': _uploadPreset,
          },
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['secure_url'];
        }
        throw Exception('Ошибка: ${response.statusCode} ${response.body}');
      } else if (file != null) {
        final request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = _uploadPreset;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();

        if (streamedResponse.statusCode == 200) {
          final json = jsonDecode(responseBody);
          return json['secure_url'];
        }
        throw Exception('Ошибка: ${streamedResponse.statusCode} $responseBody');
      }

      throw Exception('Нет данных для загрузки');
    } catch (e) {
      throw Exception('Ошибка загрузки: $e');
    }
  }
}