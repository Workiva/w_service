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

library w_service.test.http.http_provider_test;

import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_service/w_service.dart';

import '../mocks/interceptors.dart';
import '../mocks/w_http.dart';
import '../utils.dart';

void main() {
  group('HttpProvider', () {
    MockWHttp mockHttp;
    HttpProvider provider;
    List<MockWRequest> requests;

    setUp(() {
      requests = [];
      mockHttp = new MockWHttp();
      mockHttp.requests.listen(requests.add);
      provider = new HttpProvider(http: mockHttp);
      provider.uri = Uri.parse('example.com');
    });

    group('request headers', () {
      Map headers;

      setUp(() {
        headers = {'Content-Type': 'application/json', 'Content-Length': '100'};
        provider.headers = headers;
      });

      test('should be set on the underlying WRequest', () async {
        await provider.get();
        expect(requests.single.headers, equals(headers));
      });

      test('should persist over multiple requests', () async {
        await provider.get();
        await provider.get();
        expect(requests.last.headers, equals(headers));
      });
    });

    group('per request headers that do not persist', () {
      Map headers;
      Map perReqHeaders;
      Map mergedHeaders;

      setUp(() {
        headers = {'content-type': 'application/json', 'content-length': '100'};
        perReqHeaders = {'content-length': '50', 'x-custom': 'custom'};
        mergedHeaders = {
          'content-type': 'application/json',
          'content-length': '50',
          'x-custom': 'custom'
        };

        provider.headers = headers;
      });

      test('DELETE', () async {
        await provider.delete(headers: perReqHeaders);
        expect(requests.single.headers, equals(mergedHeaders));
        await provider.delete();
        expect(requests.last.headers, equals(headers));
      });

      test('HEAD', () async {
        await provider.head(headers: perReqHeaders);
        expect(requests.single.headers, equals(mergedHeaders));
        await provider.head();
        expect(requests.last.headers, equals(headers));
      });

      test('GET', () async {
        await provider.get(headers: perReqHeaders);
        expect(requests.single.headers, equals(mergedHeaders));
        await provider.get();
        expect(requests.last.headers, equals(headers));
      });

      test('OPTIONS', () async {
        await provider.options(headers: perReqHeaders);
        expect(requests.single.headers, equals(mergedHeaders));
        await provider.options();
        expect(requests.last.headers, equals(headers));
      });

      test('PATCH', () async {
        await provider.patch(headers: perReqHeaders);
        expect(requests.single.headers, equals(mergedHeaders));
        await provider.patch();
        expect(requests.last.headers, equals(headers));
      });

      test('POST', () async {
        await provider.post(headers: perReqHeaders);
        expect(requests.single.headers, equals(mergedHeaders));
        await provider.post();
        expect(requests.last.headers, equals(headers));
      });

      test('PUT', () async {
        await provider.put(headers: perReqHeaders);
        expect(requests.single.headers, equals(mergedHeaders));
        await provider.put();
        expect(requests.last.headers, equals(headers));
      });

      test('TRACE', () async {
        await provider.trace(headers: perReqHeaders);
        expect(requests.single.headers, equals(mergedHeaders));
        await provider.trace();
        expect(requests.last.headers, equals(headers));
      });
    });

    group('request data', () {
      setUp(() {
        provider.data = 'data';
      });

      test('should be set on the underlying WRequest', () async {
        await provider.get();
        verify(requests.single.data = 'data');
      });

      test('should not persist over multiple requests', () async {
        await provider.get();
        await provider.get();
        expect(requests.last.data, isNull);
      });
    });

    group('request meta', () {
      ControlledTestInterceptor interceptor;
      List<HttpContext> requestContexts;

      setUp(() {
        interceptor = new ControlledTestInterceptor();
        requestContexts = [];
        interceptor.outgoing.listen((RequestCompleter request) {
          requestContexts.add(request.context);
          request.complete();
        });
        interceptor.incoming.listen((RequestCompleter request) {
          request.complete();
        });
        provider.use(interceptor);
        provider.meta = {'custom-prop': 'custom-value'};
      });

      test('should be set on the HttpContext, available to interceptors',
          () async {
        await provider.get();
        expect(
            requestContexts.single.meta['custom-prop'], equals('custom-value'));
      });

      test('should not persist over multiple requests', () async {
        await provider.get();
        await provider.get();
        expect(requestContexts.last.meta.containsKey('custom-prop'), isFalse);
      });

      test('should be set to empty map if set to null', () {
        provider.meta = null;
        expect(provider.meta, equals({}));
      });
    });

    test('should set encoding on the underlying WRequest', () async {
      provider.encoding = LATIN1;
      await provider.get();
      verify(requests.single.encoding = LATIN1);
    });

    test('should set withCredentials on the underlying WRequest', () async {
      provider.withCredentials = true;
      await provider.get();
      verify(requests.single.withCredentials = true);
    });

    group('fork()', () {
      test('should return a new HttpProvider instance', () {
        HttpProvider fork = provider.fork();
        expect(fork is HttpProvider && fork != provider, isTrue);
      });

      test('should keep the same URI', () {
        HttpProvider fork = provider.fork();
        expect(fork.uri.toString(), equals(provider.uri.toString()));
        fork.path = '/new/path';
        expect(fork.uri.toString() != provider.uri.toString(), isTrue);
      });

      test('should keep the same headers', () {
        provider.headers = {
          'Content-Type': 'application/json',
          'Content-Length': '100',
        };
        HttpProvider fork = provider.fork();
        expect(fork.headers.toString(), equals(provider.headers.toString()));
        fork.headers['Content-Length'] = '-1';
        expect(fork.headers['Content-Length'] !=
            provider.headers['Content-Length'], isTrue);
      });

      test('should share the same interceptors', () {
        provider.use(new SimpleTestInterceptor());
        HttpProvider fork = provider.fork();
        expect(fork.interceptors.single, equals(provider.interceptors.single));
        fork.use(new SimpleTestInterceptor());
        expect(fork.interceptors.last != provider.interceptors.single, isTrue);
      });

      group('should set withCredentials', () {
        test('to false when provider\'s withCredentials is false', () {
          provider.withCredentials = false;
          HttpProvider fork = provider.fork();
          expect(fork.withCredentials, isFalse);
        });

        test('to true when provider\'s withCredentials is true', () {
          provider.withCredentials = true;
          HttpProvider fork = provider.fork();
          expect(fork.withCredentials, isTrue);
        });
      });
    });

    group('delete()', () {
      test('should send a DELETE request', () async {
        await provider.delete();
        verify(requests.single.delete());
      });

      test('should accept a URI', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.delete(uri: uri);
        verify(requests.single.uri = uri);
      });
    });

    group('get()', () {
      test('should send a GET request', () async {
        await provider.get();
        verify(requests.single.get());
      });

      test('should accept a URI', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.get(uri: uri);
        verify(requests.single.uri = uri);
      });
    });

    group('head()', () {
      test('should send a HEAD request', () async {
        await provider.head();
        verify(requests.single.head());
      });

      test('should accept a URI', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.head(uri: uri);
        verify(requests.single.uri = uri);
      });
    });

    group('options()', () {
      test('should send a OPTIONS request', () async {
        await provider.options();
        verify(requests.single.options());
      });

      test('should accept a URI', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.options(uri: uri);
        verify(requests.single.uri = uri);
      });
    });

    group('patch()', () {
      test('should send a PATCH request', () async {
        await provider.patch();
        verify(requests.single.patch());
      });

      test('should accept a URI and data', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.patch(data: 'data', uri: uri);
        verify(requests.single.uri = uri);
        verify(requests.single.data = 'data');
      });
    });

    group('post()', () {
      test('should send a POST request', () async {
        await provider.post();
        verify(requests.single.post());
      });

      test('should accept a URI and data', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.post(data: 'data', uri: uri);
        verify(requests.single.uri = uri);
        verify(requests.single.data = 'data');
      });
    });

    group('PUT', () {
      test('should send a PUT request', () async {
        await provider.put();
        verify(requests.single.put());
      });

      test('should accept a URI and data', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.put(data: 'data', uri: uri);
        verify(requests.single.uri = uri);
        verify(requests.single.data = 'data');
      });
    });

    group('TRACE', () {
      test('should send a TRACE request', () async {
        await provider.trace();
        verify(requests.single.trace());
      });

      test('should accept a URI', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.trace(uri: uri);
        verify(requests.single.uri = uri);
      });
    });

    test('sending a request with a URI should not persist URI', () async {
      Uri uri = Uri.parse('example.org/path');
      await provider.get(uri: uri);
      verify(requests.single.uri = uri);
      expect(provider.uri.toString() != uri.toString(), isTrue);
    });

    test('should throw if request fails', () async {
      mockHttp.autoFlush = false;
      Exception failed = new Exception('Failed');
      mockHttp.requests.listen((MockWRequest request) {
        request.completeError(failed);
      });
      Exception exception = await expectThrowsAsync(() async {
        await provider.get();
      });
      expect(exception, equals(failed));
    });

    group('request cancellation', () {
      test('should handle immediate cancellation', () async {
        Exception cancellation = new Exception('Canceled.');
        Exception exception = await expectThrowsAsync(() async {
          HttpFuture request = provider.get();
          request.abort(cancellation);
          await request;
        });
        expect(exception, equals(cancellation));
      });

      test('should handle cancellation after request has been sent', () async {
        Exception cancellation = new Exception('Canceled.');
        MockWRequest wTransportRequest;
        Exception exception = await expectThrowsAsync(() async {
          HttpFuture request = provider.get();
          wTransportRequest = await mockHttp.requests.first;
          request.abort(cancellation);
          await request;
        });
        expect(exception, equals(cancellation));
        verify(wTransportRequest.abort(captureAny)).called(1);
      });

      test('should handle cancellation after response has been received',
          () async {
        HttpFuture request = provider.get();
        await request;
        request.abort(new Exception('Canceled.'));
      });
    });

    group('request retrying', () {
      test('should not retry if auto retrying is disabled', () async {
        mockHttp.autoFlush = false;
        mockHttp.requests.listen((MockWRequest request) {
          request.completeError(new Exception('Failed.'));
        });
        Exception exception = await expectThrowsAsync(() async {
          await provider.get();
        });
        expect(exception.toString().contains('Failed.'), isTrue);
        expect(requests.length, equals(1));
      });

      test('should not retry if request succeeds', () async {
        provider.autoRetry();
        await provider.get();
        expect(requests.length, equals(1));
      });

      test('should disable retrying if max retries is set to 0', () async {
        mockHttp.autoFlush = false;
        provider
          ..autoRetry()
          ..autoRetry(retries: 0)
          ..retryWhen((_) => true);

        Exception failed = new Exception('Failed.');
        mockHttp.requests.listen((MockWRequest request) {
          request.completeError(failed);
        });

        Exception exception = await expectThrowsAsync(() async {
          await provider.get();
        });
        expect(exception, equals(failed));
        expect(requests.length, equals(1));
      });

      test('should retry a failed request', () async {
        mockHttp.autoFlush = false;
        provider
          ..autoRetry()
          ..retryWhen((_) => true);

        bool failed = false;
        mockHttp.requests.listen((MockWRequest request) {
          when(request.data).thenReturn(null);
          when(request.headers).thenReturn(provider.headers);
          when(request.method).thenReturn('GET');
          when(request.uri).thenReturn(provider.uri);
          if (!failed) {
            failed = true;
            request.completeError(new Exception('Failed.'));
          } else {
            request.complete();
          }
        });

        await provider.get();
        expect(requests.length, equals(2));
      });

      test('should only retry requests that meet the retryable criteria',
          () async {});

      test('should fail after exceeding maximum retry attempts', () async {
        mockHttp.autoFlush = false;
        provider
          ..autoRetry(retries: 3)
          ..retryWhen((_) => true);

        mockHttp.requests.listen((MockWRequest request) {
          when(request.data).thenReturn(null);
          when(request.headers).thenReturn(provider.headers);
          when(request.method).thenReturn('GET');
          when(request.uri).thenReturn(provider.uri);
          request.completeError(new Exception('Failed.'));
        });

        Exception exception = await expectThrowsAsync(() async {
          await provider.get();
        });
        expect(exception is MaxRetryAttemptsExceeded, isTrue);
        expect(requests.length, equals(4)); // original + 3 retries = 4
      });

      test('retryable criteria should support async function', () async {
        mockHttp.autoFlush = false;
        provider
          ..autoRetry()
          ..retryWhen((_) async => true);

        bool failed = false;
        mockHttp.requests.listen((MockWRequest request) {
          when(request.data).thenReturn(null);
          when(request.headers).thenReturn(provider.headers);
          when(request.method).thenReturn('GET');
          when(request.uri).thenReturn(provider.uri);
          if (!failed) {
            failed = true;
            request.completeError(new Exception('Failed.'));
          } else {
            request.complete();
          }
        });

        await provider.get();
        expect(requests.length, equals(2));
      });

      test(
          'should throw an ArgumentError if attempting to retry an invalid method',
          () async {
        mockHttp.autoFlush = false;
        provider
          ..autoRetry()
          ..retryWhen((_) => true);

        mockHttp.requests.listen((MockWRequest request) {
          when(request.data).thenReturn(null);
          when(request.headers).thenReturn(provider.headers);
          when(request.method).thenReturn('INVALID');
          when(request.uri).thenReturn(provider.uri);
          request.completeError(new Exception('Failed.'));
        });

        Error error = await expectThrowsAsync(() async {
          await provider.get();
        });
        expect(error is ArgumentError, isTrue);
      });

      group('methods', () {
        setUp(() {
          mockHttp.autoFlush = false;

          provider
            ..autoRetry()
            ..retryWhen((_) async => true);

          bool failed = false;
          mockHttp.requests.listen((MockWRequest request) {
            when(request.data).thenReturn(null);
            when(request.headers).thenReturn(provider.headers);
            when(request.uri).thenReturn(provider.uri);
            if (!failed) {
              failed = true;
              request.completeError(new Exception('Failed.'));
            } else {
              request.complete();
            }
          });
        });

        test('DELETE', () async {
          mockHttp.requests.listen((MockWRequest request) {
            when(request.method).thenReturn('DELETE');
          });
          await provider.delete();
          expect(requests.length, equals(2));
        });

        test('GET', () async {
          mockHttp.requests.listen((MockWRequest request) {
            when(request.method).thenReturn('GET');
          });
          await provider.get();
          expect(requests.length, equals(2));
        });

        test('HEAD', () async {
          mockHttp.requests.listen((MockWRequest request) {
            when(request.method).thenReturn('HEAD');
          });
          await provider.head();
          expect(requests.length, equals(2));
        });

        test('OPTIONS', () async {
          mockHttp.requests.listen((MockWRequest request) {
            when(request.method).thenReturn('OPTIONS');
          });
          await provider.options();
          expect(requests.length, equals(2));
        });

        test('PATCH', () async {
          mockHttp.requests.listen((MockWRequest request) {
            when(request.method).thenReturn('PATCH');
          });
          await provider.patch();
          expect(requests.length, equals(2));
        });

        test('POST', () async {
          mockHttp.requests.listen((MockWRequest request) {
            when(request.method).thenReturn('POST');
          });
          await provider.post();
          expect(requests.length, equals(2));
        });

        test('PUT', () async {
          mockHttp.requests.listen((MockWRequest request) {
            when(request.method).thenReturn('PUT');
          });
          await provider.put();
          expect(requests.length, equals(2));
        });

        test('TRACE', () async {
          mockHttp.requests.listen((MockWRequest request) {
            when(request.method).thenReturn('TRACE');
          });
          await provider.trace();
          expect(requests.length, equals(2));
        });
      });

      test('MaxRetryAttemptsExceeded should list errors from each attempt',
          () async {
        mockHttp.autoFlush = false;
        provider
          ..autoRetry(retries: 2)
          ..retryWhen((_) => true);

        int failedCount = 0;
        mockHttp.requests.listen((MockWRequest request) {
          when(request.data).thenReturn(null);
          when(request.headers).thenReturn(provider.headers);
          when(request.method).thenReturn('GET');
          when(request.uri).thenReturn(provider.uri);
          request.completeError(new Exception('Failed ${++failedCount}.'));
        });

        MaxRetryAttemptsExceeded exception = await expectThrowsAsync(() async {
          await provider.get();
        });
        expect(exception.toString(), contains('Failed 1'));
        expect(exception.toString(), contains('Failed 2'));
      });

      test('should retry 500 errors by default', () async {
        mockHttp.autoFlush = false;
        provider.autoRetry();
        provider.use(new CustomTestInterceptor(
            onIncoming: (HttpProvider provider, HttpContext context) {
          if (context.response.status >= 200 &&
              context.response.status < 300) return context;
          throw new Exception(
              'Request failed: ${context.response.status} ${context.response.statusText}');
        }));

        bool failed = false;
        mockHttp.requests.listen((MockWRequest request) {
          when(request.data).thenReturn(null);
          when(request.headers).thenReturn(provider.headers);
          when(request.method).thenReturn('GET');
          when(request.uri).thenReturn(provider.uri);
          MockWResponse response = new MockWResponse();
          if (!failed) {
            failed = true;
            when(response.status).thenReturn(500);
          } else {
            when(response.status).thenReturn(200);
          }
          request.complete(response);
        });

        await provider.get();
        expect(requests.length, equals(2));
      });

      test('should retry 502 errors by default', () async {
        mockHttp.autoFlush = false;
        provider.autoRetry();
        provider.use(new CustomTestInterceptor(
            onIncoming: (HttpProvider provider, HttpContext context) {
          if (context.response.status >= 200 &&
              context.response.status < 300) return context;
          throw new Exception(
              'Request failed: ${context.response.status} ${context.response.statusText}');
        }));

        bool failed = false;
        mockHttp.requests.listen((MockWRequest request) {
          when(request.data).thenReturn(null);
          when(request.headers).thenReturn(provider.headers);
          when(request.method).thenReturn('GET');
          when(request.uri).thenReturn(provider.uri);
          MockWResponse response = new MockWResponse();
          if (!failed) {
            failed = true;
            when(response.status).thenReturn(502);
          } else {
            when(response.status).thenReturn(200);
          }
          request.complete(response);
        });

        await provider.get();
        expect(requests.length, equals(2));
      });

      test('should retry errors that have the `retryable` flag set to true',
          () async {
        CustomTestInterceptor int = new CustomTestInterceptor(
            onOutgoing: (provider, context) {
          context.retryable = true;
          return context;
        });
        mockHttp.autoFlush = false;
        provider
          ..autoRetry()
          ..use(int);

        bool failed = false;
        mockHttp.requests.listen((MockWRequest request) {
          when(request.data).thenReturn(null);
          when(request.headers).thenReturn(provider.headers);
          when(request.method).thenReturn('GET');
          when(request.uri).thenReturn(provider.uri);
          if (!failed) {
            failed = true;
            request.completeError(new Exception('Failed.'));
          } else {
            request.complete();
          }
        });

        await provider.get();
        expect(requests.length, equals(2));
      });
    });
  });
}
