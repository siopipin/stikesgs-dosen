class AppConfig {
  AppConfig._();

  static const String appName = 'RuangDosen STIKESGS';

  // Override via: --dart-define=IS_DEVELOPMENT=false
  static const bool isDevelopment = bool.fromEnvironment(
    'IS_DEVELOPMENT',
    defaultValue: true,
  );

  // Development
  static const String apiDev = 'http://localhost:3000/mobile';
  static const String fotoUrlDev = 'http://localhost:3000/images';
  static const String apiPdfDev =
      'http://103.167.34.22/sisfo/jur/krs.cetak.php?khsid=';
  static const String imgurlDev = 'http://localhost:3000/images';

  // Production
  static const String apiProd = 'https://mystikes.gunungsari.id:3000/mobile';
  static const String fotoUrlProd = 'https://mystikes.gunungsari.id:3000/images';
  static const String apiPdfProd =
      'http://103.167.34.22/sisfo/jur/krs.cetak.php?khsid=';
  static const String imgurlProd = 'https://mystikes.gunungsari.id:3000/images';

  static String get api => isDevelopment ? apiDev : apiProd;
  static String get fotoUrl => isDevelopment ? fotoUrlDev : fotoUrlProd;
  static String get apiPdf => isDevelopment ? apiPdfDev : apiPdfProd;
  static String get imgurl => isDevelopment ? imgurlDev : imgurlProd;

  // Endpoint dosen
  static String get apiDosen => api.replaceFirst('/mobile', '/dosen/v1/');
  static String get fotoDosen => api.replaceFirst('/mobile', '/assets/dosen/photos');
}

class AppStorageKeys {
  AppStorageKeys._();

  static const String tokenDosen = 'sp_token_dosen';
  static const String loginDosen = 'sp_login_dosen';
  static const String profileDosenJson = 'sp_profile_dosen_json';
}
