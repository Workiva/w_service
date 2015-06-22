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

library w_service.test.http.http_future_test;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_service/src/http/http_future.dart';

class MockFuture extends Mock implements Future {
  // this tells Dart analyzer you meant not to implement all methods,
  // and not to hint/warn that methods are missing
  noSuchMethod(i) => super.noSuchMethod(i);
}

void main() {
  group('HttpFuture', () {
    group('standard Future methods', () {
      HttpFuture httpFuture;
      MockFuture mockFuture;

      setUp(() {
        mockFuture = new MockFuture();
        httpFuture = httpFutureFactory(mockFuture, null, null, null);
      });

      test('then() should call then() on the underlying future', () async {
        var then = (_) {};
        var onError = () {};
        when(mockFuture.then(any)).thenReturn(new Future.value());
        expect(httpFuture.then(then, onError: onError) is HttpFuture, isTrue);
        verify(mockFuture.then(then, onError: onError));
      });

      test('catchError() should call catchError() on the underlying future',
          () async {
        var onError = () {};
        var test = (_) {};
        when(mockFuture.catchError(any)).thenReturn(new Future.value());
        expect(
            httpFuture.catchError(onError, test: test) is HttpFuture, isTrue);
        verify(mockFuture.catchError(onError, test: test));
      });

      test('whenComplete() should call whenComplete() on the underlying future',
          () async {
        var action = () {};
        when(mockFuture.whenComplete(any)).thenReturn(new Future.value());
        expect(httpFuture.whenComplete(action) is HttpFuture, isTrue);
        verify(mockFuture.whenComplete(action));
      });

      test('asStream() should call asStream() on the underlying future',
          () async {
        when(mockFuture.asStream()).thenReturn(new Stream.fromIterable([]));
        expect(httpFuture.asStream() is Stream, isTrue);
        verify(mockFuture.asStream());
      });

      test('timeout() should call timeout() on the underlying future',
          () async {
        Duration timeLimit = new Duration(seconds: 1);
        var onTimeout = () {};
        when(mockFuture.timeout(any)).thenReturn(new Future.value());
        expect(
            httpFuture.timeout(timeLimit, onTimeout: onTimeout) is HttpFuture,
            isTrue);
        verify(mockFuture.timeout(timeLimit, onTimeout: onTimeout));
      });
    });

    test('abort() should call the onAbort() handler', () {
      bool aborted = false;
      var error;
      onAbort([e]) {
        aborted = true;
        error = e;
      }
      HttpFuture httpFuture =
          httpFutureFactory(new Future.value(), onAbort, null, null);
      httpFuture.abort('error');
      expect(aborted, isTrue);
      expect(error, equals('error'));
    });
  });
}
