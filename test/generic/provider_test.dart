library w_service.test.generic.provider_test;

import 'package:test/test.dart';
import 'package:w_service/w_service.dart';

class TestProvider extends Provider {}
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
      provider.useAll([new TestInterceptor(), new TestInterceptor(),]);
      expect(provider.interceptors.length, equals(2));
    });

    test('use() and useAll() should not overwrite interceptors', () {
      Provider provider = new TestProvider();
      provider.use(new TestInterceptor());
      provider.useAll([new TestInterceptor(), new TestInterceptor(),]);
      provider.use(new TestInterceptor());
      expect(provider.interceptors.length, equals(4));
    });
  });
}
