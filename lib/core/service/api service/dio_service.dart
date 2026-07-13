import 'dart:developer' as developer show log;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:indogrip/core/config/env_config.dart';

class DioService {
  static final Dio _dio = Dio();

  static void initialize() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
    );
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        client.connectionTimeout = const Duration(seconds: 10);
        client.idleTimeout = const Duration(seconds: 30);
        return client;
      },
    );
  }

  static final String url = EnvConfig.indoGripBaseUrl;
  // static final String url =
  //     'https://www.accountsure.in/development/app/inventory/the-tape-factory/software-APIs/index.php';

  static Future<Response> dioPostApiCall({data}) async {
    developer.log(EnvConfig.indoGripBaseUrl, name: 'API URL');
    return await _dio.post(url, data: data);
  }
}
