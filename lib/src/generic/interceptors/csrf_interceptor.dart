library w_service.src.generic.interceptors.csrf_interceptor;

import 'dart:async';

import 'package:w_service/w_service.dart';
import 'package:w_transport/w_transport.dart';

/// An interceptor that handles one form of protection against
/// Cross-Site Request Forgery by setting a CSRF token in a header
/// on every outgoing request and by updating the current CSRF token
/// by parsing incoming response headers.
///
/// This interceptor is designed for HTTP requests and only has an
/// effect when used with the [w_service.HttpProvider].
///
/// By default, the CSRF token header used is "x-xsrf-token".
/// This can be overridden upon construction:
///
///     var csrfInterceptor = new CsrfInterceptor(header: 'x-csrf-token');
class CsrfInterceptor extends Interceptor {
  /// Construct a new [CsrfInterceptor] instance. By default,
  /// the CSRF header used is "x-xsrf-token".
  ///
  /// To use a different header, specify one during construction:
  ///
  ///     var csrfInterceptor = new CsrfInterceptor(header: 'x-csrf-token');
  CsrfInterceptor({String header: 'x-xsrf-token'})
      : super('csrf'),
        _header = header;

  /// Get and set the CSRF token to be set on every outgoing request.
  String token = '';

  /// CSRF header name - "x-xsrf-token" by default.
  final String _header;

  /// Intercepts an outgoing request and sets the appropriate header
  /// with the latest CSRF token.
  @override
  Future<Context> onOutgoing(Provider provider, Context context) async {
    // Inject CSRF token into headers.
    if (context is HttpContext) {
      context.request.headers[_header] = token;
    }
    return context;
  }

  /// Intercepts an incoming response and checks the headers for an
  /// updated CSRF token. If found, the updated token is stored for
  /// use on all future requests.
  @override
  Future<Context> onIncoming(Provider provider, Context context) async {
    // Retrieve next token from response headers.
    if (context is HttpContext) {
      _updateToken(context.response);
    }
    return context;
  }

  /// Intercepts an incoming failed response and checks the headers
  /// for an updated CSRF token. If found, the updated token is stored
  /// for use on all future requests.
  @override
  Future<Context> onIncomingRejected(
      Provider provider, Context context, Object error) async {
    // Retrieve next token from response headers.
    if (context is HttpContext) {
      _updateToken(context.response);
    }
    throw error;
  }

  /// Update the CSRF token from a response if one is available.
  _updateToken(WResponse response) {
    if (response.headers.containsKey(_header)) {
      token = response.headers[_header];
    }
  }
}
