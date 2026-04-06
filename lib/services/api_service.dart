import 'package:dio/dio.dart';

class ApiService {
  static const String _baseUrl =
      'https://ap-southeast-1.aws.data.mongodb-api.com/app/YOUR_APP_ID/endpoint';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          // API Key akan ditambahkan dari .env / config nanti
        },
      ),
    );

    // Interceptor untuk logging (hanya di debug mode)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get client => _dio;

  /// Update base URL (misal saat pindah environment)
  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  /// Set API Key ke header
  void setApiKey(String apiKey) {
    _dio.options.headers['api-key'] = apiKey;
  }
}