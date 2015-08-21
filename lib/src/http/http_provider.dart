// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
  Function _retryWhen = (HttpContext context) => context.retryable ||
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
  /// will have the same URI, headers, withCredentials property,
  /// and will share the same interceptors.
  HttpProvider fork() {
    HttpProvider fork = new HttpProvider(
        http: _http, interceptorManager: _interceptorManager)
      ..useAll(this.interceptors)
      ..uri = this.uri
      ..headers = new Map.from(this.headers)
      ..withCredentials = this.withCredentials;

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
  ///     (HttpContext context) =>
  ///         context.retryable ||
  ///             (context.response != null &&
  ///                 [500, 502].contains(context.response.status));
  void retryWhen(test(HttpContext context)) {
    _retryWhen = test;
  }

  /// Sends a DELETE request to the given [uri].
  ///
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// Optionally, [headers] can be provided. These headers will only
  /// apply to this request and will be merged with the headers already
  /// set for this [HttpProvider].
  HttpFuture<WResponse> delete({Map<String, String> headers, Uri uri}) {
    return _send('DELETE', headers: headers, uri: uri);
  }
  /// Sends a GET request to the given [uri].
  ///
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// Optionally, [headers] can be provided. These headers will only
  /// apply to this request and will be merged with the headers already
  /// set for this [HttpProvider].
  HttpFuture<WResponse> get({Map<String, String> headers, Uri uri}) {
    return _send('GET', headers: headers, uri: uri);
  }
  /// Sends a HEAD request to the given [uri].
  ///
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// Optionally, [headers] can be provided. These headers will only
  /// apply to this request and will be merged with the headers already
  /// set for this [HttpProvider].
  HttpFuture<WResponse> head({Map<String, String> headers, Uri uri}) {
    return _send('HEAD', headers: headers, uri: uri);
  }
  /// Sends an OPTIONS request to the given [uri].
  ///
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// Optionally, [headers] can be provided. These headers will only
  /// apply to this request and will be merged with the headers already
  /// set for this [HttpProvider].
  HttpFuture<WResponse> options({Map<String, String> headers, Uri uri}) {
    return _send('OPTIONS', headers: headers, uri: uri);
  }
  /// Sends a PATCH request to the given [uri].
  ///
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// Attaches [data], if given, or uses the data from this [HttpProvider].
  ///
  /// Optionally, [headers] can be provided. These headers will only
  /// apply to this request and will be merged with the headers already
  /// set for this [HttpProvider].
  HttpFuture<WResponse> patch(
      {Object data, Map<String, String> headers, Uri uri}) {
    return _send('PATCH', data: data, headers: headers, uri: uri);
  }
  /// Sends a POST request to the given [uri].
  ///
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// Attaches [data], if given, or uses the data from this [HttpProvider].
  ///
  /// Optionally, [headers] can be provided. These headers will only
  /// apply to this request and will be merged with the headers already
  /// set for this [HttpProvider].
  HttpFuture<WResponse> post(
      {Object data, Map<String, String> headers, Uri uri}) {
    return _send('POST', data: data, headers: headers, uri: uri);
  }
  /// Sends a PUT request to the given [uri].
  ///
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// Attaches [data], if given, or uses the data from this [HttpProvider].
  ///
  /// Optionally, [headers] can be provided. These headers will only
  /// apply to this request and will be merged with the headers already
  /// set for this [HttpProvider].
  HttpFuture<WResponse> put(
      {Object data, Map<String, String> headers, Uri uri}) {
    return _send('PUT', data: data, headers: headers, uri: uri);
  }
  /// Sends a TRACE request to the given [uri].
  ///
  /// If [uri] is null, the uri on this [HttpProvider] will be used.
  ///
  /// Optionally, [headers] can be provided. These headers will only
  /// apply to this request and will be merged with the headers already
  /// set for this [HttpProvider].
  ///
  /// **Note:** For security reasons, TRACE requests are forbidden in the browser.
  HttpFuture<WResponse> trace({Map<String, String> headers, Uri uri}) {
    return _send('TRACE', headers: headers, uri: uri);
  }

  HttpFuture<WResponse> _send(String method,
      {Object data, Map<String, String> headers, Uri uri}) {
    Uri reqUri = uri != null ? uri : this.uri;
    if (reqUri == null || reqUri.toString() == '') throw new StateError(
        'HttpProvider: Cannot send a request without a URI.');

    // If this is a retry, there will be a previous request stored in the meta.
    HttpContext previousAttempt =
        meta.containsKey('previousAttempt') ? meta['previousAttempt'] : null;

    // Initialize the request context.
    int numAttempts =
        previousAttempt != null ? previousAttempt.numAttempts + 1 : 0;
    HttpContext context = httpContextFactory(method,
        numAttempts: numAttempts, retryEnabled: _shouldRetry)..meta = this.meta;

    if (previousAttempt != null) {
      context.retryErrors = new List.from(previousAttempt.retryErrors);
    }

    Map reqHeaders = new Map.from(this.headers);
    if (headers != null) {
      reqHeaders.addAll(headers);
    }

    context.request = _http.newRequest()
      ..uri = Uri.parse(reqUri.toString())
      ..encoding = this.encoding
      ..headers = reqHeaders;

    context.request.data = data != null ? data : this.data;

    if (this.withCredentials) {
      context.request.withCredentials = true;
    }

    _contexts[context.id] = context;

    this.data = null;
    this.meta = {};
    this.query = null;
    this.fragment = null;

    // Bail if the request has exceeded the maximum number of attempts.
    if (context.retryEnabled && context.numAttempts >= _maxRetryAttempts) {
      _cleanup(context);
      Future future = new Future.error(new MaxRetryAttemptsExceeded(
          'Retry attempts exceeded maximum of $_maxRetryAttempts',
          context.retryErrors));
      return httpFutureFactory(future, context.cancelRequest,
          context.request.uploadProgress, context.request.downloadProgress);
    }

    Future<WResponse> future = _dispatch(method, context)
        .catchError((error) async {
      if (context.retryEnabled && await _isRetryable(context)) {
        // Store the error so a collective error can be created later.
        context.retryErrors.add(error);
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
    return httpFutureFactory(future, context.cancelRequest,
        context.request.uploadProgress, context.request.downloadProgress);
  }

  void _checkForCancellation(HttpContext context) {
    if (context.state == States.canceled) {
      _interceptorManager.interceptOutgoingCanceled(
          this, context, context.cancellationError);
      _cleanup(context);
      throw context.cancellationError;
    }
  }

  void _cleanup(HttpContext context) {
    if (context.state != States.canceled) {
      context.state = States.complete;
    }
    if (_contexts.containsKey(context.id)) {
      _contexts.remove(context.id);
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
    context.state = States.sent;

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
    retryFork.meta['previousAttempt'] = context;

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

  String toString() {
    String msg = _message;
    for (int i = 0; i < errors.length; i++) {
      msg += '\n\tAttempt #$i: ${errors[i].toString()}';
    }
    return msg;
  }
}
