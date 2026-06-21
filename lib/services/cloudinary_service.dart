import 'dart:io';
import 'package:cloudinary/cloudinary.dart';

class CloudinaryService {
  late final Cloudinary _cloudinary;

  CloudinaryService() {
    _cloudinary = Cloudinary.signedConfig(
      apiKey: '145147764492364',
      apiSecret: 'REELR0U41xu5oMRVejSZ9iKpzC4',
      cloudName: 'dsbfuphyp',
    );
  }

  /// Загрузить фото и получить URL
  Future<String> uploadPhoto(File file, String fileName) async {
    final response = await _cloudinary.upload(
      file: file.path,
      fileName: fileName,
      folder: 'avatars',
    );

    if (response.isSuccessful) {
      return response.secureUrl!;
    } else {
      throw Exception('Ошибка загрузки: ${response.error}');
    }
  }

  /// Удалить фото
  Future<void> deletePhoto(String publicId) async {
    await _cloudinary.destroy(publicId);
  }
}