library w_service.test.mocks.contexts;

import 'package:w_service/w_service.dart';

int _contextCount = 0;

class TestContext extends Context {
  TestContext() : super('test-context-${_contextCount++}');
}
