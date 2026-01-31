class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://ophim1.com');

  static const moviesPath = '/v1/api/home';

  static const movieDetailPath = '/v1/api/phim';

  static const categoriesPath = '/v1/api/the-loai';

  static const searchPath = '/v1/api/tim-kiem?keyword=';

  static const listAllsPath = '/v1/api/danh-sach';
}
