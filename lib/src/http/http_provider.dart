library w_service.src.http.http_provider;

import 'dart:async';
import 'dart:convert';

import 'package:fluri/fluri.dart';
import 'package:w_transport/w_transport.dart';

import 'package:w_service/src/generic/interceptor_manager.dart';
import 'package:w_service/src/generic/provider.dart';
import 'package:w_service/src/http/http_context.dart';
import 'package:w_service/src/http/http_future.dart';

typedef WRequest WRequestFactory();

/// Possible states for every HTTP request, used by [HttpProvider].
enum States { canceled, complete, pending, sent }

/// By default, requests will be retried up to 3 times
/// before failing completely (when automatic retrying
/// is enabled).
const int _defaultMaxRetryAttempts = 3;

/// Counter used to create unique default IDs for HttpProviders.
int _httpProviderCount = 0;

/// Generate a unique ID for the next [HttpProvider].
String _nextHttpProviderId() {
  return 'http-provider-${_httpProviderCount++}';
}

/// A provider that sends messages over HTTP using
/// [w_transport](https://github.com/Workiva/w_transport)'s
/// `WHttp`.
///
/// Supports persistent request headers, request cancellation,
/// upload/download progress monitoring, request retrying,
/// and anything that
/// /// [w_transport](https://github.com/Workiva/w_transport)'s
/// requests support.
class HttpProvider extends Provider with FluriMixin {
  /// Request headers to send on every request.
  Map<String, String> headers = {};

  /// Gets and sets the data to send on the next request.
  /// This does not persist over multiple requests.
  Object data;

  /// Encoding to use on the request data.
  Encoding encoding = UTF8;

  /// Whether or not to send the request with credentials.
  ///
  /// **Note:** this only has an effect client-side.
  bool withCredentials = false;

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
  int _maxRetryAttempts = _defaultMaxRetryAttempts;

  Map<String, dynamic> _meta = {};

  /// Test function that helps determine whether or not a failed
  /// request is retryable.
  Function _retryWhen = (HttpContext context) =>
  (context.meta.containsKey('retryable') && context.meta['retryable']) ||
  (context.response != null &&
  [500, 502].contains(context.response.status));

  /// Whether or not automatic request retrying is enabled.
  bool _shouldRetry = false;

  /// Construct a new [HttpProvider] instance.
  HttpProvider({String id, WHttp http, InterceptorManager interceptorManager})
      : super(id != null ? id : _nextHttpProviderId()),
        _http = http != null ? http : new WHttp(),
        _interceptorManager = interceptorManager != null
            ? interceptorManager
            : new InterceptorManager();

  /// Update the meta configuration for the next request.
  /// This does not persist over multiple requests.
  void set meta(Map<String, dynamic> meta) {
    if (meta == null) {
      meta = {};
    }
    _meta = meta;
  }
  Map<String, dynamic> get meta => _meta;

  /// Enables automatic request retrying. Will retry failed requests
  /// (that fit retryable criteria) up to a maximum number of attempts.
  void autoRetry({int retries: _defaultMaxRetryAttempts}) {
    if (retries <= 0) {
      _shouldRetry = false;
      _maxRetryAttempts = 0;
    } else {
      _shouldRetry = true;
      _maxRetryAttempts = retries;
    }
  }

  /// Fork this [HttpProvider] instance. The returned fork
  /// will have the same URI, headers, and will share the
  /// same interceptors.
  HttpProvider fork() {
    HttpProvider fork = new HttpProvider(
        http: _http, interceptorManager: _interceptorManager)
      ..useAll(this.interceptors)
      ..uri = this.uri
      ..headers = new Map.from(this.headers);

    if (_shouldRetry) {
      fork.autoRetry(retries: _maxRetryAttempts);
      fork.retryWhen(_retryWhen);
    }
    return fork;
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
  ///         => (context.meta.containsKey('retryable') && context.meta['retryable'])
  ///            || (context.response != null && [500, 502].contains(context.response.status));
  void retryWhen(test(HttpContext context)) {
    _retryWhen = test;
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

    // Initialize the request context.
    HttpContext context = httpContextFactory();
    _contexts[context.id] = context;
    context.meta = this.meta;
    context.meta['state'] = States.pending;
    context.meta['method'] = method;

    context.request = _http.newRequest()
      ..uri = Uri.parse(reqUri.toString())
      ..encoding = this.encoding
      ..headers = new Map.from(this.headers);

    context.request.data = data != null ? data : this.data;
    ;

    if (this.withCredentials) {
      context.request.withCredentials = true;
    }

    // Initialize/update the retryable meta info if applicable.
    bool isRetryable = context.meta.containsKey('retry-enabled') &&
        context.meta['retry-enabled'];
    if (_shouldRetry && !isRetryable) {
      context.meta['retry-enabled'] = true;
      context.meta['attempts'] = 0;
    } else if (isRetryable) {
      context.meta['attempts']++;
    }

    this.data = null;
    this.meta = {};
    this.query = null;
    this.fragment = null;

    void abort([error]) {
      context.meta['state'] = States.canceled;
      this._cancellations[context.id] = error;
      context.request.abort(error);
    }
    context.abort = abort;

    // Bail if the request has exceeded the maximum number of attempts.
    if (isRetryable && context.meta['attempts'] >= _maxRetryAttempts) {
      _cleanup(context);
      Future future = new Future.error(new MaxRetryAttemptsExceeded(
          'Retry attempts exceeded maximum of $_maxRetryAttempts',
          context.meta['retryErrors']));
      return httpFutureFactory(future, abort, context.request.uploadProgress,
          context.request.downloadProgress);
    }

    Future<WResponse> future = _dispatch(method, context)
        .catchError((error) async {
      if (context.meta.containsKey('retry-enabled') &&
          context.meta['retry-enabled'] &&
          await _isRetryable(context)) {
        // Store the error so a collective error can be created later.
        if (!context.meta.containsKey('retryErrors')) {
          context.meta['retryErrors'] = [];
        }
        context.meta['retryErrors'].add(error);
        // Attempt a retry before giving up.
        context.response = await _retry(context);
        // Retry eventually succeeded.
        _cleanup(context);
        return context;
      } else {
        // Retries not enabled or request did not meet retryable criteria.
        _cleanup(context);
        throw error;
      }
    }).catchError((error) async {
      _cleanup(context);
      throw error;
    }).then((HttpContext context) async => context.response);
    return httpFutureFactory(future, abort, context.request.uploadProgress,
        context.request.downloadProgress);
  }

  void _checkForCancellation(HttpContext context) {
    if (context.meta['state'] == States.canceled) {
      Object error = _cancellations[context.id];
      _interceptorManager.interceptOutgoingCanceled(this, context, error);
      _cleanup(context);
      throw error;
    }
  }

  void _cleanup(HttpContext context) {
    if (context.meta['state'] != States.canceled) {
      context.meta['state'] = States.complete;
    }
    if (_contexts.containsKey(context.id)) {
      _contexts.remove(context.id);
    }
    if (_cancellations.containsKey(context.id)) {
      _cancellations.remove(context.id);
    }
  }

  Future<HttpContext> _dispatch(String method, HttpContext context) async {
    // Apply outgoing interceptors.
    context = await _interceptorManager.interceptOutgoing(this, context);
    _checkForCancellation(context);

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
    Object error;
    try {
      context.response = await request;
    } on WHttpException catch (e) {
      context.response = e.response;
      error = e;
    }

    _checkForCancellation(context);

    // Apply incoming interceptors.
    context = await _interceptorManager.interceptIncoming(this, context, error);

    _cleanup(context);
    return context;
  }

  Future<bool> _isRetryable(HttpContext context) async {
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

/// Exception that occurs when a request sent via an
/// [HttpProvider] instance fails to complete successfully
/// in the maximum allowed number of retry attempts.
class MaxRetryAttemptsExceeded implements Exception {
  final List<Object> errors;
  final String _message;

  MaxRetryAttemptsExceeded(this._message, [List errors])
      : this.errors = errors != null ? errors : [];

  String get message => toString();

  String toString() {
    String msg = _message;
    for (int i = 0; i < errors.length; i++) {
      msg += '\n\tAttempt #$i: ${errors[i].toString()}';
    }
    return msg;
  }
}
