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

library w_service.src.http.http_context;

import 'package:w_transport/w_transport.dart';

import 'package:w_service/src/generic/context.dart';
import 'package:w_service/src/http/http_provider.dart' show States;

int _count = 0;
const String _idPrefix = 'http-context-';

/// Creates a new [HttpContext] instance.
/// This is used internally but is not exported,
/// allowing the [HttpContext] class to be exported
/// without allowing new instances of it to be constructed,
/// since that should not be necessary.
HttpContext httpContextFactory(String method,
        {int numAttempts, bool retryEnabled}) =>
    new HttpContext._(method,
        numAttempts: numAttempts, retryEnabled: retryEnabled);

/// Context for service messages sent over HTTP.
/// In addition to the properties on [Context],
/// [HttpContext] includes [request] and [response]
/// properties that are specific to HTTP transport.
class HttpContext extends Context {
  /// Error/reason for cancellation.
  Object cancellationError;

  /// HTTP method.
  final String method;

  /// Number of attempts made so far. Only applicable if auto
  /// retrying is enabled.
  final int numAttempts;

  /// Whether or not a request can be retried. Should be set
  /// by interceptors when creating an error to indicate that
  /// the error can be recovered from.
  ///
  /// Example: TimeoutInterceptor will set this to true when
  /// a request is canceled due to a timeout since timeout
  /// errors are often transient.
  bool retryable = false;

  /// Whether or not auto retrying was enabled on the provider
  /// at the time this message was created.
  final bool retryEnabled;

  /// List of accumulated errors for each attempted request.
  /// Used to create a collective error should the max number
  /// of retry attempts be exceeded.
  List retryErrors = [];

  /// [w_transport](https://github.com/Workiva/w_transport)
  /// WRequest object used to send the HTTP request.
  WRequest request;

  /// [w_transport](https://github.com/Workiva/w_transport)
  /// WResponse object representing the response to the request.
  WResponse response;

  /// Current state of the HTTP message.
  States state = States.pending;

  /// Construct a new [HttpContext] instance.
  /// The [request] and [response] properties should be
  /// populated as they become available.
  HttpContext._(String this.method, {int numAttempts, bool retryEnabled: false})
      : super('$_idPrefix${_count++}'),
        this.numAttempts = numAttempts,
        this.retryEnabled = retryEnabled;

  /// Cancel the request.
  void cancelRequest([Object error]) {
    state = States.canceled;
    cancellationError = error;
    request.abort(error);
  }
}
