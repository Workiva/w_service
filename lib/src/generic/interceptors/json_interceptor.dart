library w_service.src.generic.interceptors.json_interceptor;

import 'dart:async';
import 'dart:convert';

import '../../http/http_context.dart';
import '../context.dart';
import '../interceptor.dart';
import '../provider.dart';

/// An interceptor that handles encoding and decoding of data
/// payloads on outgoing and incoming messages, respectively.
///
/// This interceptor is designed for HTTP requests and only has an
/// effect when used with the [HttpProvider].
///
/// On outgoing messages, this interceptor will try to encode the
/// data into a JSON string. This should work for simple data
/// structures like Maps or Lists and primitives. If the encoding
/// fails, the error will be swallowed and the data will be left
/// unmodified.
///
/// On incoming messages, this interceptor will try to read the
/// message data as a string and decode the string into a Map or List.
/// If the decoding fails, the error will be swallowed and the data
/// will be left unmodified.
class JsonInterceptor extends Interceptor {
  /// Construct a new [JsonInterceptor] instance.
  JsonInterceptor() : super('json');

  /// Intercepts an outgoing request and attempts to encode the data
  /// to a JSON string.
  @override
  Future<Context> onOutgoing(Provider provider, Context context) async {
    if (context is HttpContext) {
      // If the Content-Type header has already been set,
      // bail so that we don't overwrite or conflict with
      // another similar process.
      if (context.request.headers.containsKey('content-type') && context.request.headers['content-type'] != 'application/json') return context;

      context.request.headers['content-type'] = 'application/json';
      if (context.request.data != null && context.request.data is! String) {
        try {
          context.request.data = JSON.encode(context.request.data);
        } catch (e) {}
      }
    }
    return context;
  }

  /// Intercepts an incoming response and attempts to decode the data
  /// to a Map or List.
  @override
  Future<Context> onIncoming(Provider provider, Context context) async {
    if (context is HttpContext) {
      try {
        context.response.update(JSON.decode(await context.response.asText()));
      } catch (e) {}
    }
    return context;
  }
}
