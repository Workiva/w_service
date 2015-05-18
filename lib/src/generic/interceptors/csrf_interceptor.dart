library w_service.src.generic.interceptors.csrf_interceptor;

import 'dart:async';

import 'package:w_transport/w_http.dart';

import '../../http/http_context.dart';
import '../context.dart';
import '../interceptor.dart';
import '../provider.dart';

class CsrfInterceptor extends Interceptor {
  CsrfInterceptor({String header: 'x-xsrf-token'})
      : super('csrf'),
        _header = header;

  String token = '';

  final String _header;

  Future<Context> onOutgoing(Provider provider, Context context) async {
    // Inject CSRF token into headers.
    if (context is HttpContext) {
      context.request.headers[_header] = token;
    }
    return context;
  }

  Future<Context> onIncoming(Provider provider, Context context) async {
    // Retrieve next token from response headers.
    if (context is HttpContext) {
      _updateToken(context.response);
    }
    return context;
  }

  Future<Context> onIncomingRejected(
      Provider provider, Context context, Object error) async {
    // Retrieve next token from response headers.
    if (context is HttpContext) {
      _updateToken(context.response);
    }
    throw error;
  }

  _updateToken(WResponse response) {
    if (response.headers.containsKey(_header)) {
      token = response.headers[_header];
    }
  }
}
