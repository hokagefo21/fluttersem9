import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      'Accept': 'application/json',
      'X-App-Name': 'PostExplorer',
      'X-Client-Version': '1.0',
    });
    handler.next(options);
  }
}

Dio createDio() =>
    Dio(
        BaseOptions(
          baseUrl: 'https://jsonplaceholder.typicode.com',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 15),
        ),
      )
      ..interceptors.add(ApiInterceptor())
      ..interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          logPrint: (value) {
            if (kDebugMode) debugPrint(value.toString());
          },
        ),
      );
