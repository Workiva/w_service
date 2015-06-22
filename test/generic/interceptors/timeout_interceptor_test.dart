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

library w_service.test.generic.interceptors.timeout_interceptor_test;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_service/w_service.dart';
import 'package:w_service/src/http/http_context.dart';

import '../../mocks/w_http.dart';

void main() {
  group('TimeoutInterceptor', () {
    TimeoutInterceptor interceptor;

    setUp(() {
      interceptor = new TimeoutInterceptor(
          maxRequestDuration: new Duration(milliseconds: 50));
    });

    group('http', () {
      Map<String, String> headers;
      HttpContext context;
      HttpProvider provider;

      setUp(() {
        headers = {};
        context = httpContextFactory();
        context.abort = ([error]) {
          context.request.abort(error);
        };
        context.request = new MockWRequest();
        context.response = new MockWResponse();
        when(context.request.headers).thenReturn(headers);
        when(context.response.headers).thenReturn(headers);
        provider = new HttpProvider(http: new MockWHttp());
      });

      test('should default to a 15 second max request duration', () async {
        expect(
            new TimeoutInterceptor().maxRequestDuration.inSeconds, equals(15));
      });

      test('should do nothing if request is canceled before timeout', () async {
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        interceptor.onOutgoingCanceled(provider, context, null);
        await new Future.delayed(new Duration(milliseconds: 50));
      });

      test('should do nothing if request completes before timeout', () async {
        expect(
            await interceptor.onOutgoing(provider, context), equals(context));
        interceptor.onIncomingFinal(provider, context, null);
        await new Future.delayed(new Duration(milliseconds: 50));
      });

      test('should cancel the request if it does not complete in time',
          () async {
        await interceptor.onOutgoing(provider, context);
        await new Future.delayed(new Duration(milliseconds: 50));
        expect(verify(context.request.abort(captureAny)).captured.single
            .toString()
            .contains('Timeout threshold'), isTrue);
      });
    });
  });
}
