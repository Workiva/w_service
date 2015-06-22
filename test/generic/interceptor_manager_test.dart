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

library w_service.test.generic.interceptor_manager_test;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:w_service/w_service.dart';

import '../mocks/contexts.dart';
import '../mocks/interceptors.dart';
import '../utils.dart';

class TestProvider extends Provider {
  TestProvider() : super('test-provider');
}

void main() {
  group('InterceptorManager', () {
    InterceptorManager manager;
    TestProvider provider;
    TestContext context;

    setUp(() {
      manager = new InterceptorManager();
      provider = new TestProvider();
      context = new TestContext();
    });

    group('outgoing', () {
      test('should return identical context if there are no interceptors',
          () async {
        expect(await manager.interceptOutgoing(provider, context),
            equals(context));
      });

      test('should use an outgoing interceptor', () async {
        MockSimpleTestInterceptor mockInt =
            spy(new MockSimpleTestInterceptor(), new SimpleTestInterceptor());
        provider.use(mockInt);
        expect(await manager.interceptOutgoing(provider, context),
            equals(context));
        verify(mockInt.onOutgoing(provider, context)).called(1);
      });

      test('should throw with the error if interceptor throws', () async {
        CustomTestInterceptor testInt = new CustomTestInterceptor(
            onOutgoing: (provider, context) {
          throw new Exception('Rejected.');
        });
        provider.use(testInt);
        await expectThrowsAsync(() async {
          await manager.interceptOutgoing(provider, context);
        }, isException);
      });

      test('should apply multiple outgoing interceptors in order', () async {
        MockControlledTestInterceptor mockInt1 = spy(
            new MockControlledTestInterceptor(),
            new ControlledTestInterceptor());
        MockControlledTestInterceptor mockInt2 = spy(
            new MockControlledTestInterceptor(),
            new ControlledTestInterceptor());
        provider.useAll([mockInt1, mockInt2]);
        Future<Context> interception =
            manager.interceptOutgoing(provider, context);
        RequestCompleter request;

        verifyNever(mockInt1.onOutgoing(any, any));
        verifyNever(mockInt2.onOutgoing(any, any));

        request = await mockInt1.outgoing.first;
        verify(mockInt1.onOutgoing(provider, context)).called(1);
        await request.complete();

        request = await mockInt2.outgoing.first;
        verify(mockInt2.onOutgoing(provider, context)).called(1);
        await request.complete();

        expect(await interception, equals(context));
      });

      test('should allow modification of the context', () async {
        CustomTestInterceptor testInt = new CustomTestInterceptor(
            onOutgoing: (provider, context) async {
          context.meta['modified'] = true;
          return context;
        });
        provider.use(testInt);
        context = await manager.interceptOutgoing(provider, context);
        expect(context.meta['modified'], isTrue);
      });

      test('should allow replacement of the context', () async {
        CustomTestInterceptor testInt = new CustomTestInterceptor(
            onOutgoing: (provider, context) async {
          return new TestContext();
        });
        provider.use(testInt);
        expect(await manager.interceptOutgoing(provider, context) != context,
            isTrue);
      });

      test('should throw if 1 interceptor throws', () async {
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onOutgoing: (provider, context) async {
          throw new Exception('Rejected.');
        });
        provider.use(rejector);

        await expectThrowsAsync(() async {
          await manager.interceptOutgoing(provider, context);
        }, isException);
      });

      test(
          'should throw if first of 2 intercepors throws; second not called, both onOutgoingCanceled() called',
          () async {
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onOutgoing: (provider, context) async {
          throw new Exception('Rejected.');
        });
        SimpleTestInterceptor second = new SimpleTestInterceptor();

        MockCustomTestInterceptor rejectorSpy =
            spy(new MockCustomTestInterceptor(), rejector);
        MockSimpleTestInterceptor secondSpy =
            spy(new MockSimpleTestInterceptor(), second);
        provider.useAll([rejectorSpy, secondSpy]);

        await expectThrowsAsync(() async {
          await manager.interceptOutgoing(provider, context);
        });

        verifyNever(secondSpy.onOutgoing(any, any));
        verify(rejectorSpy.onOutgoingCanceled(provider, context, any))
            .called(1);
        verify(secondSpy.onOutgoingCanceled(provider, context, any)).called(1);
      });

      test('should complete if 2 outgoing interceptors complete', () async {
        SimpleTestInterceptor first = new SimpleTestInterceptor();
        SimpleTestInterceptor second = new SimpleTestInterceptor();
        MockSimpleTestInterceptor firstSpy =
            spy(new MockSimpleTestInterceptor(), first);
        MockSimpleTestInterceptor secondSpy =
            spy(new MockSimpleTestInterceptor(), second);
        provider.useAll([firstSpy, secondSpy]);

        await manager.interceptOutgoing(provider, context);
      });

      test('should throw if first of 2 interceptors complete but second throws',
          () async {
        SimpleTestInterceptor first = new SimpleTestInterceptor();
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onOutgoing: (provider, context) {
          throw new Exception('Rejected.');
        });
        MockSimpleTestInterceptor firstSpy =
            spy(new MockSimpleTestInterceptor(), first);
        MockCustomTestInterceptor rejectorSpy =
            spy(new MockCustomTestInterceptor(), rejector);
        provider.useAll([firstSpy, rejectorSpy]);

        await expectThrowsAsync(() async {
          await manager.interceptOutgoing(provider, context);
        });

        verify(firstSpy.onOutgoing(provider, context)).called(1);
        verify(rejectorSpy.onOutgoing(provider, context)).called(1);
      });

      test('should call all onOutgoingCanceled() methods if canceled',
          () async {
        Exception exception = new Exception('Rejected.');
        SimpleTestInterceptor first = new SimpleTestInterceptor();
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onOutgoing: (provider, context) {
          throw exception;
        });
        MockSimpleTestInterceptor firstSpy =
            spy(new MockSimpleTestInterceptor(), first);
        MockCustomTestInterceptor rejectorSpy =
            spy(new MockCustomTestInterceptor(), rejector);
        provider.useAll([firstSpy, rejectorSpy]);

        await expectThrowsAsync(() async {
          await manager.interceptOutgoing(provider, context);
        });

        verify(firstSpy.onOutgoingCanceled(provider, context, exception))
            .called(1);
        verify(rejectorSpy.onOutgoingCanceled(provider, context, exception))
            .called(1);
      });
    });

    group('incoming', () {
      test('should return identical context if there are no interceptors',
          () async {
        expect(await manager.interceptIncoming(provider, context),
            equals(context));
      });

      test('should use an incoming interceptor', () async {
        MockSimpleTestInterceptor mockInt =
            spy(new MockSimpleTestInterceptor(), new SimpleTestInterceptor());
        provider.use(mockInt);
        expect(await manager.interceptIncoming(provider, context),
            equals(context));
        verify(mockInt.onIncoming(provider, context)).called(1);
      });

      test('should apply multiple incoming interceptors in order', () async {
        MockControlledTestInterceptor mockInt1 = spy(
            new MockControlledTestInterceptor(),
            new ControlledTestInterceptor());
        MockControlledTestInterceptor mockInt2 = spy(
            new MockControlledTestInterceptor(),
            new ControlledTestInterceptor());
        provider.useAll([mockInt1, mockInt2]);
        Future<Context> interception =
            manager.interceptIncoming(provider, context);
        RequestCompleter request;

        verifyNever(mockInt1.onIncoming(any, any));
        verifyNever(mockInt2.onIncoming(any, any));

        request = await mockInt1.incoming.first;
        verify(mockInt1.onIncoming(provider, context)).called(1);
        await request.complete();

        request = await mockInt2.incoming.first;
        verify(mockInt2.onIncoming(provider, context)).called(1);
        await request.complete();

        expect(await interception, equals(context));
      });

      test('should allow modification of the context', () async {
        CustomTestInterceptor testInt = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          context.meta['modified'] = true;
          return context;
        });
        provider.use(testInt);
        context = await manager.interceptIncoming(provider, context);
        expect(context.meta['modified'], isTrue);
      });

      test('should allow modification of the context when rejecting', () async {
        CustomTestInterceptor modifier = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          context.meta['modified'] = true;
          throw new Exception('Rejected.');
        });
        provider.use(modifier);
        await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        });
        expect(context.meta['modified'], isTrue);
      });

      test('should allow modification of the context when recovering',
          () async {
        bool rejected = false;
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          if (!rejected) {
            rejected = true;
            throw new Exception('Rejected.');
          }
          return context;
        });
        CustomTestInterceptor recoverer = new CustomTestInterceptor(
            onIncomingRejected: (provider, context, error) async {
          context.meta['modified'] = true;
          return context;
        });
        provider.useAll([rejector, recoverer]);
        context = await manager.interceptIncoming(provider, context);
        expect(context.meta['modified'], isTrue);
      });

      test('should allow modification of the context when re-throwing',
          () async {
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) {
          throw new Exception('Rejected.');
        });
        CustomTestInterceptor modifier = new CustomTestInterceptor(
            onIncomingRejected: (provider, context, error) {
          context.meta['modified'] = true;
          throw error;
        });
        provider.useAll([rejector, modifier]);
        await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        });
        expect(context.meta['modified'], isTrue);
      });

      test('should allow replacement of the context', () async {
        CustomTestInterceptor testInt = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          return new TestContext();
        });
        provider.use(testInt);
        expect(await manager.interceptIncoming(provider, context) != context,
            isTrue);
      });

      test('should throw if 1 interceptor throws', () async {
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          throw new Exception('Rejected.');
        });
        provider.use(rejector);

        await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        }, isException);
      });

      test('should throw if 1 interceptor rejects', () async {
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          throw new Exception('Rejected.');
        });
        provider.use(rejector);

        await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        }, isException);
      });

      test('should complete if 1 interceptor completes', () async {
        MockSimpleTestInterceptor mockInt =
            spy(new MockSimpleTestInterceptor(), new SimpleTestInterceptor());
        provider.use(mockInt);

        await manager.interceptIncoming(provider, context);
        verify(mockInt.onIncoming(provider, context)).called(1);
      });

      test('should throw if 1 interceptor throws and no interceptors recover',
          () async {
        SimpleTestInterceptor first = new SimpleTestInterceptor();
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          throw new Exception('Rejected.');
        });
        MockSimpleTestInterceptor mockFirst =
            spy(new MockSimpleTestInterceptor(), first);
        MockCustomTestInterceptor mockRejector =
            spy(new MockCustomTestInterceptor(), rejector);
        provider.useAll([mockFirst, mockRejector]);

        await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        });

        verify(mockFirst.onIncoming(provider, context)).called(1);
        verify(mockRejector.onIncoming(provider, context)).called(1);
        verify(mockFirst.onIncomingRejected(provider, context, any)).called(1);
        verify(mockRejector.onIncomingRejected(provider, context, any))
            .called(1);
      });

      test(
          'should restart interceptor chain when switching from standard to rejected',
          () async {
        SimpleTestInterceptor first = new SimpleTestInterceptor();
        SimpleTestInterceptor second = new SimpleTestInterceptor();
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          throw new Exception('Rejected.');
        });

        MockSimpleTestInterceptor mockFirst =
            spy(new MockSimpleTestInterceptor(), first);
        MockSimpleTestInterceptor mockSecond =
            spy(new MockSimpleTestInterceptor(), second);
        MockCustomTestInterceptor mockRejector =
            spy(new MockCustomTestInterceptor(), rejector);
        provider.useAll([mockFirst, mockSecond, mockRejector]);

        await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        });

        verify(mockFirst.onIncomingRejected(provider, context, any)).called(1);
        verify(mockSecond.onIncomingRejected(provider, context, any)).called(1);
        verify(mockRejector.onIncomingRejected(provider, context, any))
            .called(1);
      });

      test(
          'should restart interceptor chain when switching back from rejected to standard',
          () async {
        bool rejected = false;
        CustomTestInterceptor rejectOnce = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          if (!rejected) {
            rejected = true;
            throw new Exception('Rejected.');
          }
          return context;
        });
        SimpleTestInterceptor second = new SimpleTestInterceptor();
        CustomTestInterceptor recoverer = new CustomTestInterceptor(
            onIncomingRejected: (provider, context, error) async {
          return context;
        });

        MockCustomTestInterceptor mockRejectOnce =
            spy(new MockCustomTestInterceptor(), rejectOnce);
        MockSimpleTestInterceptor mockSecond =
            spy(new MockSimpleTestInterceptor(), second);
        MockCustomTestInterceptor mockRecoverer =
            spy(new MockCustomTestInterceptor(), recoverer);
        provider.useAll([mockRejectOnce, mockSecond, mockRecoverer]);

        await manager.interceptIncoming(provider, context);

        verify(mockRejectOnce.onIncoming(provider, context)).called(2);
        verify(mockSecond.onIncoming(provider, context)).called(1);
        verify(mockRecoverer.onIncoming(provider, context)).called(1);
        verify(mockRejectOnce.onIncomingRejected(provider, context, any))
            .called(1);
        verify(mockSecond.onIncomingRejected(provider, context, any)).called(1);
        verify(mockRecoverer.onIncomingRejected(provider, context, any))
            .called(1);
      });

      test(
          'should call all onIncomingFinal() methods after the context is finalized (successfully)',
          () async {
        bool rejected = false;
        CustomTestInterceptor rejectOnce = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          if (!rejected) {
            rejected = true;
            throw new Exception('Rejected.');
          }
          return context;
        });
        SimpleTestInterceptor second = new SimpleTestInterceptor();
        CustomTestInterceptor recoverer = new CustomTestInterceptor(
            onIncomingRejected: (provider, context, error) async {
          return context;
        });

        MockCustomTestInterceptor mockRejectOnce =
            spy(new MockCustomTestInterceptor(), rejectOnce);
        MockSimpleTestInterceptor mockSecond =
            spy(new MockSimpleTestInterceptor(), second);
        MockCustomTestInterceptor mockRecoverer =
            spy(new MockCustomTestInterceptor(), recoverer);
        provider.useAll([mockRejectOnce, mockSecond, mockRecoverer]);

        await manager.interceptIncoming(provider, context);

        verify(mockRejectOnce.onIncomingFinal(provider, context, null))
            .called(1);
        verify(mockSecond.onIncomingFinal(provider, context, null)).called(1);
        verify(mockRecoverer.onIncomingFinal(provider, context, null))
            .called(1);
      });

      test(
          'should call all onIncomingFinal() methods after the context is finalized (rejected)',
          () async {
        Exception exception = new Exception('Rejected.');
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          throw exception;
        });
        SimpleTestInterceptor second = new SimpleTestInterceptor();
        bool recovered = false;
        CustomTestInterceptor recoverOnce = new CustomTestInterceptor(
            onIncomingRejected: (provider, context, error) async {
          if (!recovered) {
            recovered = true;
            return context;
          }
          throw error;
        });

        MockCustomTestInterceptor mockRejector =
            spy(new MockCustomTestInterceptor(), rejector);
        MockSimpleTestInterceptor mockSecond =
            spy(new MockSimpleTestInterceptor(), second);
        MockCustomTestInterceptor mockRecoverOnce =
            spy(new MockCustomTestInterceptor(), recoverOnce);
        provider.useAll([mockRejector, mockSecond, mockRecoverOnce]);

        await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        });

        verify(mockRejector.onIncomingFinal(provider, context, exception))
            .called(1);
        verify(mockSecond.onIncomingFinal(provider, context, exception))
            .called(1);
        verify(mockRecoverOnce.onIncomingFinal(provider, context, exception))
            .called(1);
      });

      test('should not allow the interceptor chain cycle to exceed 10 attempts',
          () async {
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          throw new Exception('Rejected.');
        });
        CustomTestInterceptor recoverer = new CustomTestInterceptor(
            onIncomingRejected: (provider, context, error) async {
          return context;
        });
        MockCustomTestInterceptor rejectorSpy =
            spy(new MockCustomTestInterceptor(), rejector);
        provider.useAll([rejectorSpy, recoverer]);

        Exception exception = await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        });

        verify(rejectorSpy.onIncoming(provider, context)).called(10);
        expect(exception
            .toString()
            .contains('attempts exceeded while intercepting'), isTrue);
      });

      test(
          'should allow the max number of interceptor chain cycle attempts to be configurable',
          () async {
        CustomTestInterceptor rejector = new CustomTestInterceptor(
            onIncoming: (provider, context) async {
          throw new Exception('Rejected.');
        });
        CustomTestInterceptor recoverer = new CustomTestInterceptor(
            onIncomingRejected: (provider, context, error) async {
          return context;
        });
        MockCustomTestInterceptor rejectorSpy =
            spy(new MockCustomTestInterceptor(), rejector);
        provider.useAll([rejectorSpy, recoverer]);
        manager.maxIncomingInterceptorAttempts = 4;

        Exception exception = await expectThrowsAsync(() async {
          await manager.interceptIncoming(provider, context);
        });

        verify(rejectorSpy.onIncoming(provider, context)).called(4);
        expect(exception
            .toString()
            .contains('attempts exceeded while intercepting'), isTrue);
      });

      test(
          'should throw if max number of interceptor chain cycle attempts set to 0 or less',
          () {
        expect(() {
          manager.maxIncomingInterceptorAttempts = 0;
        }, throwsArgumentError);
      });
    });
  });
}
