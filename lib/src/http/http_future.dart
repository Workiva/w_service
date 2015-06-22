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

library w_service.src.http.http_future;

import 'dart:async';

import 'package:w_transport/w_transport.dart';

/// Creates a new [HttpFuture] instance.
HttpFuture httpFutureFactory(Future future, onAbort([error]),
        Stream<WProgress> uploadProgress, Stream<WProgress> downloadProgress) =>
    new HttpFuture._fromFuture(
        future, onAbort, uploadProgress, downloadProgress);

/// Augmented [Future] that represents the status of an HTTP request.
///
/// The request can be canceled and the upload & download
/// progress can be monitored from an [HttpFuture] instance.
class HttpFuture<T> implements Future<T> {
  /// [w_transport](https://github.com/Workiva/w_transport)
  /// [WProgress] stream for this HTTP request's download.
  final Stream<WProgress> downloadProgress;

  /// [w_transport](https://github.com/Workiva/w_transport)
  /// [WProgress] stream for this HTTP request's upload.
  final Stream<WProgress> uploadProgress;

  /// Underlying [Future] that drives the async behavior.
  Future<T> _future;

  /// Handler for when [abort] is called.
  Function _onAbort;

  HttpFuture._fromFuture(
      this._future, this._onAbort, this.uploadProgress, this.downloadProgress);

  /// Cancel this request. If the request has already finished,
  /// this will do nothing.
  void abort([error]) {
    _onAbort(error);
  }

  Stream<T> asStream() => _future.asStream();

  Future catchError(Function onError, {bool test(error)}) =>
      new HttpFuture._fromFuture(_future.catchError(onError, test: test),
          _onAbort, uploadProgress, downloadProgress);

  Future timeout(Duration timeLimit, {onTimeout()}) =>
      new HttpFuture._fromFuture(
          _future.timeout(timeLimit, onTimeout: onTimeout), _onAbort,
          uploadProgress, downloadProgress);

  Future then(f(T value), {Function onError}) => new HttpFuture._fromFuture(
      _future.then(f, onError: onError), _onAbort, uploadProgress,
      downloadProgress);

  Future<T> whenComplete(action()) => new HttpFuture._fromFuture(
      _future.whenComplete(action), _onAbort, uploadProgress, downloadProgress);
}
