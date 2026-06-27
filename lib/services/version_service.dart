class VersionService {
  /// Версия приложения. Менять здесь при каждом релизе.
  static const String version = '1.0.5-Beta';

  static String get versionString => 'v$version';
}