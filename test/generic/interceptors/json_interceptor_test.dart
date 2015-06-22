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

      test('should set the content-type header to application/json', () async {
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        expect(headers['content-type'], equals('application/json'));
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

      test('should not overwrite the content-type header', () async {
        headers['content-type'] = 'text/plain';
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        expect(context.request.headers['content-type'], equals('text/plain'));
      });

      test(
          'should not try to encode the data if the content-type header has already been set',
          () async {
        headers['content-type'] = 'text/plain';
        Map data = {
          'name': 'Supported Transports',
          'items': ['HTTP', 'WebSocket']
        };
        when(context.request.data).thenReturn(data);
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        verifyNever(context.request.data = JSON.encode(data));
      });
    });
  });
}
