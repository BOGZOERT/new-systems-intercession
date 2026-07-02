class VersionService {
  /// Версия приложения. Менять здесь при каждом релизе.
  static const String version = '1.1.1-Beta';

  static String get versionString => 'v$version';
}