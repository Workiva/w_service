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

library w_service.test.generic.provider_test;

import 'package:test/test.dart';
import 'package:w_service/w_service.dart';

class TestProvider extends Provider {
  TestProvider() : super('test-provider');
}

class TestInterceptor extends Interceptor {
  TestInterceptor() : super('test-interceptor');
}

void main() {
  group('Provider', () {
    test('use() should register a single Interceptor', () {
      Provider provider = new TestProvider();
      provider.use(new TestInterceptor());
      provider.use(new TestInterceptor());
      expect(provider.interceptors.length, equals(2));
      expect(provider.interceptors[0] is TestInterceptor, isTrue);
    });

    test('useAll() should register a list of Interceptors', () {
      Provider provider = new TestProvider();
      provider.useAll([
        new TestInterceptor(),
        new TestInterceptor(),
      ]);
      expect(provider.interceptors.length, equals(2));
    });

    test('use() and useAll() should not overwrite interceptors', () {
      Provider provider = new TestProvider();
      provider.use(new TestInterceptor());
      provider.useAll([
        new TestInterceptor(),
        new TestInterceptor(),
      ]);
      provider.use(new TestInterceptor());
      expect(provider.interceptors.length, equals(4));
    });
  });
}
