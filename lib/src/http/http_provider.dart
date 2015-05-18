library w_service.src.providers.http_provider;

import 'dart:async';
import 'dart:convert';

import 'package:fluri/fluri.dart';
import 'package:w_transport/w_http.dart';

import '../generic/interceptor_manager.dart';
import '../generic/provider.dart';
import 'http_context.dart';
import 'http_future.dart';

typedef WRequest WRequestFactory();

/// By default, requests will be retried up to 3 times
/// before failing completely (when automatic retrying
/// is enabled).
const int _defaultMaxRetryAttempts = 3;

enum States { cancelled, complete, pending, sent }

/// TODO
class HttpProvider extends Provider with FluriMixin {
  /// Construct a new [HttpProvider] instance.
  HttpProvider({WHttp http, InterceptorManager interceptorManager})
      : super(),
        _http = http != null ? http : new WHttp(),
        _interceptorManager = interceptorManager != null
            ? interceptorManager
            : new InterceptorManager();

  /// Request headers to send on every request.
  Map<String, String> headers = {};

  /// Set the data to send on the next request.
  /// This does not persist over multiple requests.
  void set data(Object data) {}
  Object get data => null;

  /// Encoding to use on the request data.
  Encoding encoding = UTF8;

  /// Update the meta configuration for the next request.
  /// This does not persist over multiple requests.
  Map<String, dynamic> meta = {};

  /// Whether or not to send the request with credentials.
  /// This is often necessary for cross-origin requests,
  /// so it is enabled by default.
  ///
  /// **Note:** this only has an effect client-side.
  bool withCredentials = true;

  /// Cancellation errors keyed by request ID.
  Map<String, dynamic> _cancellations = {};

  /// Request contexts keyed by request ID.
  Map<String, HttpContext> _contexts = {};

  /// [WHttp] client used to create and send HTTP requests.
  WHttp _http;

  /// [InterceptorManager] instance that will handle the application
  /// of this [Provider]'s interceptors to this [Provider]'s requests.
  InterceptorManager _interceptorManager;

  /// Number of times to retry a request before failing completely.
  int _retryAttempts = _defaultMaxRetryAttempts;

  /// Test function that helps determine whether or not a failed
  /// request is retryable.
  Function _retryWhen = (HttpContext context) =>
      [500, 502].contains(context.response.status) || context.meta['retryable'];

  /// Whether or not automatic request retrying is enabled.
  bool _shouldRetry = false;

  /// Enables automatic request retrying. Will retry failed requests
  /// (that fit retryable criteria) up to a maximum number of attempts.
  void autoRetry({int retries: _defaultMaxRetryAttempts}) {
    if (retries <= 0) {
      _shouldRetry = false;
      _retryAttempts = 0;
    }
    _shouldRetry = true;
    _retryAttempts = retries;
  }

  /// Set a test function that determines whether or not a failed
  /// request should be retried.
  ///
  ///     HttpProvider provider = new HttpProvider()
  ///       ..autoRetry()
  ///       ..retryWhen((HttpContext context) => context.response.status == 500);
  ///
  /// By default, the following criteria is used:
  ///
  ///     (HttpContext context)
  ///         => [500, 502].contains(context.response.status) || context.meta['retryable'];
  void retryWhen(bool test(HttpContext context)) {
    _retryWhen = test;
  }

  /// Fork this [HttpProvider] instance. The returned fork
  /// will have the same URI, headers, and will share the
  /// same interceptors.
  ///
  /// This is useful for...
  HttpProvider fork() {
    HttpProvider fork = new HttpProvider(
        http: _http, interceptorManager: _interceptorManager)
      ..useAll(this.interceptors)
      ..uri = this.uri
      ..headers = new Map.from(this.headers);

    if (_shouldRetry) {
      fork.autoRetry(retries: _retryAttempts);
    }
    return fork;
  }

  /// Sends a DELETE request to the given [uri].
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  HttpFuture<WResponse> delete([Uri uri]) {
    return _send('DELETE', uri);
  }
  /// Sends a GET request to the given [uri].
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  HttpFuture<WResponse> get([Uri uri]) {
    return _send('GET', uri);
  }
  /// Sends a HEAD request to the given [uri].
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  HttpFuture<WResponse> head([Uri uri]) {
    return _send('HEAD', uri);
  }
  /// Sends an OPTIONS request to the given [uri].
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  HttpFuture<WResponse> options([Uri uri]) {
    return _send('OPTIONS', uri);
  }
  /// Sends a PATCH request to the given [uri].
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  /// Attaches [data], if given, or uses the data from this [HttpProvider].
  HttpFuture<WResponse> patch([Uri uri, Object data]) {
    return _send('PATCH', uri, data);
  }
  /// Sends a POST request to the given [uri].
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  /// Attaches [data], if given, or uses the data from this [HttpProvider].
  HttpFuture<WResponse> post([Uri uri, Object data]) {
    return _send('POST', uri, data);
  }
  /// Sends a PUT request to the given [uri].
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  /// Attaches [data], if given, or uses the data from this [HttpProvider].
  HttpFuture<WResponse> put([Uri uri, Object data]) {
    return _send('PUT', uri, data);
  }
  /// Sends a TRACE request to the given [uri].
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// **Note:** For security reasons, TRACE requests are forbidden in the browser.
  HttpFuture<WResponse> trace([Uri uri]) {
    return _send('TRACE', uri);
  }

  HttpFuture<WResponse> _send(String method, [Uri uri, Object data]) {
    Uri reqUri = uri != null ? uri : this.uri;
    if (reqUri == null || reqUri.toString() == '') throw new StateError(
        'HttpProvider: Cannot send a request without a URI.');

    HttpContext context = httpContextFactory();
    _contexts[context.id] = context;
    context.meta = this.meta;
    context.meta['state'] = States.pending;

    context.request = _http.newRequest()
      ..uri = Uri.parse(reqUri.toString())
      ..data = data != null ? data : this.data
      ..encoding = this.encoding
      ..headers = this.headers;

    if (this.withCredentials) {
      context.request.withCredentials = true;
    }

    this.data = null;
    this.meta = {};
    this.query = '';
    this.fragment = '';

    void abort([error]) {
      context.meta['state'] = States.cancelled;
      this._cancellations[context.id] = error;
      context.request.abort();
    }

    Future future = _dispatch(method, context);
    return httpFutureFactory(future, abort, context.request.uploadProgress,
        context.request.downloadProgress);
  }

  Future<HttpContext> _dispatch(String method, HttpContext context) async {
    // Apply outgoing interceptors.
    context = await _interceptorManager.interceptOutgoing(this, context);
    _checkForCancellation(context);

    try {
      // Dispatch request.
      Future<WResponse> request;
      switch (method) {
        case 'DELETE':
          request = context.request.delete();
          break;
        case 'GET':
          request = context.request.get();
          break;
        case 'HEAD':
          request = context.request.head();
          break;
        case 'OPTIONS':
          request = context.request.options();
          break;
        case 'PATCH':
          request = context.request.patch();
          break;
        case 'POST':
          request = context.request.post();
          break;
        case 'PUT':
          request = context.request.put();
          break;
        case 'TRACE':
          request = context.request.trace();
          break;
      }
      context.meta['state'] = States.sent;

      // Receive response.
      context.response = await request;

      // Apply incoming interceptors.
      context = await _interceptorManager.interceptIncoming(this, context);
    } catch (e) {
      // Check to see if the failure is retryable.
      if (await _isRetryable(context)) {
        // Attempt a retry before giving up.
        try {
          context.response = await _retry(context);
          // Retry eventually succeeded.
        } catch (e) {
          // Exceeded maximum retry attempts.
          _cleanup(context);
          throw e;
        }
      } else {
        _cleanup(context);
        throw e;
      }
    }
    _cleanup(context);
    return context;
  }

  void _checkForCancellation(HttpContext context) {
    if (context.meta['state'] == States.cancelled) {
      Object error = _cancellations[context.id];
      _cleanup(context);
      throw error;
    }
  }

  void _cleanup(HttpContext context) {
    if (context.meta['state'] != States.cancelled) {
      context.meta['state'] = States.complete;
    }
    if (_contexts.containsKey(context.id)) {
      _contexts.remove(context.id);
    }
    if (_cancellations.containsKey(context.id)) {
      _cancellations.remove(context.id);
    }
  }

  Future<bool> _isRetryable(HttpContext context) async {
    if (context.response == null) {
      return false;
    }
    var result = _retryWhen(context);
    if (result is Future) {
      result = await result;
    }
    return result;
  }

  Future<WResponse> _retry(HttpContext context) async {
    HttpProvider retryFork = fork()
      ..data = context.request.data
      ..headers = context.request.headers
      ..meta = context.meta
      ..uri = context.request.uri;

    switch (context.request.method) {
      case 'DELETE':
        return retryFork.delete();
      case 'GET':
        return retryFork.get();
      case 'HEAD':
        return retryFork.head();
      case 'OPTIONS':
        return retryFork.options();
      case 'PATCH':
        return retryFork.patch();
      case 'POST':
        return retryFork.post();
      case 'PUT':
        return retryFork.put();
      case 'TRACE':
        return retryFork.trace();
      default:
        throw new ArgumentError(
            'Cannot retry - illegal HTTP method: ${context.request.method}');
    }
  }
}
