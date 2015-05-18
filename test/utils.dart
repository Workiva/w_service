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
