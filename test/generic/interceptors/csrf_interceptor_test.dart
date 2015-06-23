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

library w_service.test.generic.interceptors.csrf_interceptor_test;

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_service/w_service.dart';
import 'package:w_service/src/http/http_context.dart';

import '../../mocks/w_http.dart';
import '../../utils.dart';

void main() {
  group('CsrfInterceptor', () {
    CsrfInterceptor interceptor;

    group('http', () {
      Map<String, String> headers;
      HttpContext context;
      HttpProvider provider;

      setUp(() {
        headers = {};
        context = httpContextFactory('GET');
        context.request = new MockWRequest();
        context.response = new MockWResponse();
        when(context.request.headers).thenReturn(headers);
        when(context.response.headers).thenReturn(headers);
        provider = new HttpProvider(http: new MockWHttp());
      });

      test('should set the CSRF token on an outgoing request\'s headers',
          () async {
        interceptor = new CsrfInterceptor(header: 'x-xsrf-token');
        interceptor.token = 'token';
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        expect(headers['x-xsrf-token'], equals('token'));
      });

      test('should use `x-xsrf-token` as the default CSRF header', () async {
        interceptor.token = 'token';
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        expect(headers['x-xsrf-token'], equals('token'));
      });

      test('should set any empty token by default', () async {
        interceptor = new CsrfInterceptor(header: 'x-xsrf-token');
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        expect(headers['x-xsrf-token'], equals(''));
      });

      test('should not overwrite the token if already set', () async {
        context.request.headers['x-xsrf-token'] = 'original-token';
        interceptor = new CsrfInterceptor(header: 'x-xsrf-token');
        interceptor.token = 'different-token';
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        expect(headers['x-xsrf-token'], equals('original-token'));
      });

      test('should update the token from an incoming response', () async {
        interceptor = new CsrfInterceptor(header: 'x-xsrf-token');
        headers['x-xsrf-token'] = 'new-token';
        expect(
            await interceptor.onIncoming(provider, context), equals(context));
        expect(interceptor.token, equals('new-token'));
      });

      test('should update the token from a failed incoming response', () async {
        interceptor = new CsrfInterceptor(header: 'x-xsrf-token');
        headers['x-xsrf-token'] = 'new-token';
        Object exception = await expectThrowsAsync(() async {
          await interceptor.onIncomingRejected(provider, context, 'error');
        });
        expect(exception, equals('error'));
        expect(interceptor.token, equals('new-token'));
      });

      test(
          'should not update the token if an incoming response does not have a new token',
          () async {
        interceptor = new CsrfInterceptor(header: 'x-xsrf-token');
        interceptor.token = 'token';
        expect(
            await interceptor.onIncoming(provider, context), equals(context));
        expect(interceptor.token, equals('token'));
      });
    });
  });
}
