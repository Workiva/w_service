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

library w_service.test.mocks.interceptors;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:w_service/w_service.dart';

int _simpleIntCount = 0;
int _customIntCount = 0;
int _controlledIntCount = 0;

/// The [RequestCompleter] allows controlled completion of
/// a request. The [ControlledTestInterceptor] produces streams
/// of [RequestCompleter]s.
class RequestCompleter {
  RequestCompleter(this._completer, this.context, [this.error]);

  Context context;

  Object error;

  Completer<Context> _completer;

  Future complete([value]) {
    _completer.complete(value != null ? value : context);
    return _completer.future;
  }

  Future completeError([error]) {
    _completer.completeError(error != null ? error : this.error);
    return _completer.future;
  }
}

/// Mock class for the [SimpleTestInterceptor]
class MockSimpleTestInterceptor extends Mock implements SimpleTestInterceptor {
  // this tells Dart analyzer you meant not to implement all methods,
  // and not to hint/warn that methods are missing
  noSuchMethod(i) => super.noSuchMethod(i);
}

/// Simple test interceptor that immediately completes with
/// default behavior.
///
/// onOutgoing
///   - completes with given context
/// onOutgoingCanceled
///   - nothing
/// onIncoming
///   - completes with given context
/// onIncomingRejected
///   - re-throws the given error
/// onIncomingFinal
///   - nothing
class SimpleTestInterceptor extends Interceptor {
  SimpleTestInterceptor()
      : super('simple-test-interceptor-${_simpleIntCount++}');
}

/// Mock class for the [CustomTestInterceptor]
class MockCustomTestInterceptor extends Mock implements CustomTestInterceptor {
  // this tells Dart analyzer you meant not to implement all methods,
  // and not to hint/warn that methods are missing
  noSuchMethod(i) => super.noSuchMethod(i);
}

/// Custom test interceptor that uses default behavior unless
/// overridden upon construction.
///
/// The constructor accepts optional functions for each interceptor
/// method that will be used in place of the default behavior.
///
/// Effectively, this lets you create a custom interceptor on
/// the fly without needing an actual class.
class CustomTestInterceptor extends Interceptor {
  Function _onOutgoing;
  Function _onOutgoingCanceled;
  Function _onIncoming;
  Function _onIncomingRejected;
  Function _onIncomingFinal;

  CustomTestInterceptor(
      {onOutgoing(Provider provider, Context context),
      onOutgoingCanceled(Provider provider, Context context, Object error),
      onIncoming(Provider provider, Context context),
      onIncomingRejected(Provider provider, Context context, Object error),
      onIncomingFinal(Provider provider, Context context, Object error)})
      : super('custom-test-interceptor${_customIntCount++}'),
        _onOutgoing = onOutgoing,
        _onOutgoingCanceled = onOutgoingCanceled,
        _onIncoming = onIncoming,
        _onIncomingRejected = onIncomingRejected,
        _onIncomingFinal = onIncomingFinal;

  Future<Context> onOutgoing(Provider provider, Context context) async {
    if (_onOutgoing != null) {
      return _onOutgoing(provider, context);
    }
    return super.onOutgoing(provider, context);
  }

  void onOutgoingCanceled(Provider provider, Context context, Object error) {
    if (_onOutgoingCanceled != null) {
      _onOutgoingCanceled(provider, context, error);
    } else {
      super.onOutgoingCanceled(provider, context, error);
    }
  }

  Future<Context> onIncoming(Provider provider, Context context) async {
    if (_onIncoming != null) {
      return _onIncoming(provider, context);
    }
    return super.onIncoming(provider, context);
  }

  Future<Context> onIncomingRejected(
      Provider provider, Context context, Object error) async {
    if (_onIncomingRejected != null) {
      return _onIncomingRejected(provider, context, error);
    }
    return super.onIncomingRejected(provider, context, error);
  }

  void onIncomingFinal(Provider provider, Context context, Object error) {
    if (_onIncomingFinal != null) {
      _onIncomingFinal(context, error);
    } else {
      super.onIncomingFinal(provider, context, error);
    }
  }
}

/// Mock class for the [ControlledTestInterceptor]
class MockControlledTestInterceptor extends Mock
    implements ControlledTestInterceptor {
  // this tells Dart analyzer you meant not to implement all methods,
  // and not to hint/warn that methods are missing
  noSuchMethod(i) => super.noSuchMethod(i);
}

/// Controlled test interceptor that holds requests until
/// flushed during the following stages:
///   - onOutgoing
///   - onIncoming
///   - onIncomingRejected
///
/// Use the [RequestCompleter] streams to listen for every
/// request that enters one of these methods and use the
/// [RequestCompleter] to manually complete the requests.
class ControlledTestInterceptor extends Interceptor {
  StreamController<RequestCompleter> _outgoingRequestStreamController =
      new StreamController();
  StreamController<RequestCompleter> _incomingRequestStreamController =
      new StreamController();
  StreamController<RequestCompleter> _incomingRejectedRequestStreamController =
      new StreamController();

  ControlledTestInterceptor()
      : super('controlled-test-interceptor-${_controlledIntCount++}');

  Stream<RequestCompleter> get outgoing =>
      _outgoingRequestStreamController.stream;
  Stream<RequestCompleter> get incoming =>
      _incomingRequestStreamController.stream;
  Stream<RequestCompleter> get incomingRejected =>
      _incomingRejectedRequestStreamController.stream;

  Future<Context> onOutgoing(Provider provider, Context context) async {
    Completer<Context> completer = new Completer<Context>();
    _outgoingRequestStreamController
        .add(new RequestCompleter(completer, context));
    return completer.future;
  }

  Future<Context> onIncoming(Provider provider, Context context) async {
    Completer<Context> completer = new Completer<Context>();
    _incomingRequestStreamController
        .add(new RequestCompleter(completer, context));
    return completer.future;
  }

  Future<Context> onIncomingRejected(
      Provider provider, Context context, Object error) async {
    Completer<Context> completer = new Completer<Context>();
    _incomingRejectedRequestStreamController
        .add(new RequestCompleter(completer, context, error));
    return completer.future;
  }
}
