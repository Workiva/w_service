library w_service.test.providers.http_provider_test;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_service/src/http/http_future.dart';

class MockFuture extends Mock implements Future {}

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
