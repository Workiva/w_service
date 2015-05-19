library w_service.test.generic.interceptors.json_interceptor_test;

import 'dart:async';
import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_service/w_service.dart';
import 'package:w_service/src/http/http_context.dart';

import '../../mocks/w_http.dart';

void main() {
  group('JsonInterceptor', () {
    JsonInterceptor interceptor;

    setUp(() {
      interceptor = new JsonInterceptor();
    });

    group('http', () {
      Map<String, String> headers;
      HttpContext context;
      HttpProvider provider;

      setUp(() {
        headers = {};
        context = httpContextFactory();
        context.request = new MockWRequest();
        context.response = new MockWResponse();
        when(context.request.headers).thenReturn(headers);
        when(context.response.headers).thenReturn(headers);
        provider = new HttpProvider(http: new MockWHttp());
      });

      test('should set the Content-Type header to application/json', () async {
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        expect(headers['Content-Type'], equals('application/json'));
      });

      test('should encode request data', () async {
        Map data = {
          'name': 'Supported Transports',
          'items': ['HTTP', 'WebSocket']
        };
        when(context.request.data).thenReturn(data);
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        verify(context.request.data = JSON.encode(data));
      });

      test('should not throw if request data cannot be encoded', () async {
        Stream stream = new Stream.fromIterable([1, 2]);
        when(context.request.data).thenReturn(stream);
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        expect(context.request.data is Stream, isTrue);
      });

      test('should decode response data', () async {
        Map data = {
          'name': 'Supported Transports',
          'items': ['HTTP', 'WebSocket']
        };
        when(context.response.asText())
            .thenReturn(new Future.value(JSON.encode(data)));
        expect(
            await interceptor.onIncoming(provider, context), equals(context));
        expect(verify(context.response.update(captureAny)).captured.single,
            equals(data));
      });

      test('should not throw if response data cannot be decoded', () async {
        when(context.response.asText())
            .thenReturn(new Future.value('non-json-decodable text'));
        expect(
            await interceptor.onIncoming(provider, context), equals(context));
        verifyNever(context.response.update(captureAny));
      });
    });
  });
}
