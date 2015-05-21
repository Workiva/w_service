library w_service.src.http.http_context;

import 'package:w_transport/w_transport.dart';

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
/// In addition to the properties on [Context],
/// [HttpContext] includes [request] and [response]
/// properties that are specific to HTTP transport.
class HttpContext extends Context {
  /// Construct a new [HttpContext] instance.
  /// The [request] and [response] properties should be
  /// populated as they become available.
  HttpContext._() : super('$_idPrefix${_count++}');

  /// [w_transport](https://github.com/Workiva/w_transport)
  /// WRequest object used to send the HTTP request.
  WRequest request;

  /// [w_transport](https://github.com/Workiva/w_transport)
  /// WResponse object representing the response to the request.
  WResponse response;
}
