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

library w_service.test.utils;

import 'dart:async';

import 'package:test/test.dart';

Future<Object> expectThrowsAsync(Future f(), [Matcher throwsMatcher]) async {
  var exception;
  try {
    await f();
  } catch (e) {
    exception = e;
  }
  if (exception == null) throw new Exception(
      'Expected function to throw asynchronously, but did not.');
  if (throwsMatcher != null) {
    expect(exception, throwsMatcher);
  }
  return exception;
}
