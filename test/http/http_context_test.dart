library w_service.test.providers.http_context_test;

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
