import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../features/auth/models/auth_session_record.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient extends GetConnect {
  ApiClient(this._sessionLoader) {
    httpClient.baseUrl = ApiConfig.baseUrl;
    httpClient.timeout = ApiConfig.connectTimeout;
    httpClient.defaultContentType = 'application/json';
    httpClient.addRequestModifier<dynamic>((request) async {
      request.headers['Accept'] = 'application/json';

      final session = await _sessionLoader();
      if (session.accessToken.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      return request;
    });
  }

  final Future<AuthSessionRecord> Function() _sessionLoader;

  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    _logRequest('GET', path, query: query);
    final response = await get<dynamic>(path, query: query);
    return _unwrapResponse(response, method: 'GET', path: path);
  }

  Future<dynamic> postJson(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
  }) async {
    _logRequest('POST', path, body: body, query: query);
    final response = await post<dynamic>(path, body, query: query);
    return _unwrapResponse(response, method: 'POST', path: path);
  }

  Future<dynamic> putJson(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
  }) async {
    _logRequest('PUT', path, body: body, query: query);
    final response = await put<dynamic>(path, body, query: query);
    return _unwrapResponse(response, method: 'PUT', path: path);
  }

  Future<dynamic> deleteJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    _logRequest('DELETE', path, query: query);
    final response = await delete<dynamic>(path, query: query);
    return _unwrapResponse(response, method: 'DELETE', path: path);
  }

  Future<dynamic> postMultipart(
    String path, {
    required String fieldName,
    required String filePath,
    Map<String, dynamic>? fields,
  }) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    _logRequest(
      'POST',
      path,
      body: <String, dynamic>{
        ...?fields,
        fieldName: fileName,
      },
    );
    final formData = FormData(<String, dynamic>{
      ...?fields,
      fieldName: MultipartFile(
        File(filePath),
        filename: fileName,
      ),
    });

    final response = await post<dynamic>(path, formData);
    return _unwrapResponse(response, method: 'POST', path: path);
  }

  dynamic _unwrapResponse(
    Response<dynamic> response, {
    required String method,
    required String path,
  }) {
    _logResponse(method, path, response);

    if (response.isOk) {
      return response.body;
    }

    if (response.statusCode == null) {
      throw const ApiException(
        'Server tak reach nahi ho raha. API URL, phone/LAN connectivity, aur Android cleartext HTTP config check karein.',
      );
    }

    final body = response.body;
    if (body is Map) {
      final data = Map<String, dynamic>.from(body);
      final message = _extractMessage(data);
      throw ApiException(message, statusCode: response.statusCode);
    }

    throw ApiException(
      'Request failed with status ${response.statusCode ?? 'unknown'}.',
      statusCode: response.statusCode,
    );
  }

  String _extractMessage(Map<String, dynamic> data) {
    final directMessage = data['message']?.toString().trim();
    if (directMessage != null && directMessage.isNotEmpty) {
      return directMessage;
    }

    final errors = data['errors'];
    if (errors is Map) {
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value != null) {
          return value.toString();
        }
      }
    }

    return 'Something went wrong while talking to the server.';
  }

  void _logRequest(
    String method,
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
  }) {
    if (!_shouldLog) {
      return;
    }

    debugPrint('API -> $method ${ApiConfig.baseUrl}$path');
    if (query != null && query.isNotEmpty) {
      debugPrint('API query -> $query');
    }
    if (body != null) {
      debugPrint('API body -> $body');
    }
  }

  void _logResponse(
    String method,
    String path,
    Response<dynamic> response,
  ) {
    if (!_shouldLog) {
      return;
    }

    debugPrint(
      'API <- $method ${ApiConfig.baseUrl}$path [${response.statusCode ?? 'NO_STATUS'}]',
    );
    if (!response.isOk && response.body != null) {
      debugPrint('API error body -> ${response.body}');
    }
  }

  bool get _shouldLog => ApiConfig.enableApiLogs && !kReleaseMode;
}
