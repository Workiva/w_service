library w_service.test.providers.http_provider_test;

import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_service/w_service.dart';

import '../mocks/interceptors.dart';
import '../mocks/w_http.dart';


void main() {
  group('HttpProvider', () {
    HttpProvider provider;
    List<MockWRequest> requests;

    setUp(() {
      requests = [];
      MockWHttp mockHttp = new MockWHttp();
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
        verify(requests.single.headers = headers);
      });

      test('should persist over multiple requests', () async {
        await provider.get();
        await provider.get();
        verify(requests.last.headers = headers);
      });
    });

    group('request data', () {
      setUp(() {
        provider.data = 'data';
      });

      test('should be set on the underlying WRequest', () async {
        await provider.get();
        verify(requests.single.data = provider.data);
      });

      test('should not persist over multiple requests', () async {
        await provider.get();
        await provider.get();
        verify(requests.last.data = null);
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
        interceptor.incoming.listen((RequestCompleter request){
          request.complete();
        });
        provider.use(interceptor);
        provider.meta = {'custom-prop': 'custom-value'};
      });

      test('should be set on the HttpContext, available to interceptors',
          () async {
        await provider.get();
        expect(requestContexts.single.meta['custom-prop'], equals('custom-value'));
      });

      test('should not persist over multiple requests', () async {
        await provider.get();
        await provider.get();
        expect(requestContexts.last.meta.containsKey('custom-prop'), isFalse);
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
    });

    group('delete()', () {
      test('should send a DELETE request', () async {
        await provider.delete();
        verify(requests.single.delete());
      });

      test('should accept a URI', () async {
        Uri uri = Uri.parse('example.org/path');
        await provider.delete(uri);
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
        await provider.get(uri);
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
        await provider.head(uri);
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
        await provider.options(uri);
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
        await provider.patch(uri, 'data');
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
        await provider.post(uri, 'data');
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
        await provider.put(uri, 'data');
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
        await provider.trace(uri);
        verify(requests.single.uri = uri);
      });
    });

    test('sending a request with a URI should not persist URI', () async {
      Uri uri = Uri.parse('example.org/path');
      await provider.get(uri);
      verify(requests.single.uri = uri);
      expect(provider.uri.toString() != uri.toString(), isTrue);
    });
  });
}
