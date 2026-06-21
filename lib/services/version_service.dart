import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static String? _version;

  /// Инициализировать — вызвать один раз при старте
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _version = 'v${info.version}';
  }

  /// Получить строку версии
  static String get versionString => _version ?? 'v1.0.0';
}