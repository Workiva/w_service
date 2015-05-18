library w_service.src.contexts.http_context;

import 'package:w_transport/w_http.dart';

import '../generic/context.dart';

int _count = 0;
const String _idPrefix = 'HttpContext';

/// Creates a new [HttpContext] instance.
/// This is used internally but is not exported,
/// allowing the [HttpContext] class to be exported
/// without allowing new instances of it to be constructed,
/// since that should not be necessary.
HttpContext httpContextFactory() => new HttpContext._();

/// Context for service messages sent over HTTP.
class HttpContext extends Context {
  /// Construct a new [HttpContext] instance.
  /// The [request] and [response] properties should be
  /// populated as they become available.
  HttpContext._() : super('$_idPrefix${_count++}');

  /// Request object used to send the HTTP request.
  WRequest request;

  /// Response object representing the response to the request.
  WResponse response;
}
