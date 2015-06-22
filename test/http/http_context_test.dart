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

library w_service.test.http.http_context_test;

import 'package:test/test.dart';
import 'package:w_service/src/http/http_context.dart';

void main() {
  group('HttpContext', () {
    test('should create a unique identifier upon construction', () {
      HttpContext context1 = httpContextFactory();
      HttpContext context2 = httpContextFactory();
      expect(context1.id.isNotEmpty && context2.id.isNotEmpty, isTrue);
      expect(context1 != context2, isTrue);
    });
  });
}
