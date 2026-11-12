import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin HTTP client for the Google Apps Script web app (REST-style API).
/// Reads use GET, writes use POST with a JSON body sent as text/plain
/// (avoids CORS preflight). Apps Script answers POSTs with a 302 redirect
/// that must be followed with a GET, which is handled manually here.
class SheetsApiProvider {
  final http.Client _client = http.Client();
  String _url = '';
  String _key = '';

  bool get isConfigured => _url.isNotEmpty;

  void configure(String url, String key) {
    _url = url.trim();
    _key = key.trim();
  }

  Future<Map<String, dynamic>> get(String action) => _run(() async {
        final base = Uri.parse(_requireUrl());
        final uri = base.replace(queryParameters: {
          ...base.queryParameters,
          'action': action,
          if (_key.isNotEmpty) 'key': _key,
        });
        final res = await _client.get(uri).timeout(AppConstants.requestTimeout);
        return _decode(res);
      });

  Future<Map<String, dynamic>> post(String action, Map<String, dynamic> payload, {String? requestId}) =>
      _run(() async {
        final uri = Uri.parse(_requireUrl());
        final body = jsonEncode({
          'action': action,
          'key': _key,
          'requestId': requestId ?? '',
          'payload': payload,
        });
        const headers = {'Content-Type': 'text/plain;charset=utf-8'};
        http.Response res;
        if (kIsWeb) {
          res = await _client.post(uri, headers: headers, body: body).timeout(AppConstants.requestTimeout);
        } else {
          final req = http.Request('POST', uri)
            ..followRedirects = false
            ..headers.addAll(headers)
            ..body = body;
          final streamed = await _client.send(req).timeout(AppConstants.requestTimeout);
          res = await http.Response.fromStream(streamed);
          var hops = 0;
          while ({301, 302, 303, 307, 308}.contains(res.statusCode) && hops < 5) {
            final location = res.headers['location'];
            if (location == null) break;
            res = await _client.get(Uri.parse(location)).timeout(AppConstants.requestTimeout);
            hops++;
          }
        }
        return _decode(res);
      });

  String _requireUrl() {
    if (_url.isEmpty) throw ApiException('Google Sheets is not connected yet.');
    return _url;
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode != 200) {
      throw ApiException('Server responded with status ${res.statusCode}.');
    }
    dynamic json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException(
          'Unexpected response. Make sure the URL ends with /exec and the web app access is set to "Anyone".');
    }
    if (json is! Map) throw ApiException('Unexpected response format.');
    if (json['ok'] != true) throw ApiException(json['error']?.toString() ?? 'Unknown server error.');
    final data = json['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _run(Future<Map<String, dynamic>> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request timed out. Check your connection and try again.');
    } on http.ClientException {
      throw ApiException('Cannot reach Google Sheets. Check your internet connection and the Web App URL.');
    } on FormatException {
      throw ApiException('The Web App URL is not valid.');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }
}
