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
class MockSimpleTestInterceptor extends Mock implements SimpleTestInterceptor {}

/// Simple test interceptor that immediately completes with
/// default behavior.
///
/// onOutgoing
///   - completes with given context
/// onOutgoingCancelled
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
class MockCustomTestInterceptor extends Mock implements CustomTestInterceptor {}

/// Custom test interceptor that uses default behavior unless
/// overridden upon construction.
///
/// The constructor accepts optional functions for each interceptor
/// method that will be used in place of the default behavior.
///
/// Effectively, this lets you create a custom interceptor on
/// the fly without needing an actual class.
class CustomTestInterceptor extends Interceptor {
  CustomTestInterceptor({onOutgoing(Provider provider, Context context),
      onOutgoingCancelled(Provider provider, Context context, Object error),
      onIncoming(Provider provider, Context context),
      onIncomingRejected(Provider provider, Context context, Object error),
      onIncomingFinal(Context context, Object error)})
      : super('custom-test-interceptor${_customIntCount++}'),
        _onOutgoing = onOutgoing,
        _onOutgoingCancelled = onOutgoingCancelled,
        _onIncoming = onIncoming,
        _onIncomingRejected = onIncomingRejected,
        _onIncomingFinal = onIncomingFinal;

  Function _onOutgoing;
  Function _onOutgoingCancelled;
  Function _onIncoming;
  Function _onIncomingRejected;
  Function _onIncomingFinal;

  Future<Context> onOutgoing(Provider provider, Context context) async {
    if (_onOutgoing != null) {
      return _onOutgoing(provider, context);
    }
    return super.onOutgoing(provider, context);
  }

  void onOutgoingCancelled(Provider provider, Context context, Object error) {
    if (_onOutgoingCancelled != null) {
      _onOutgoingCancelled(provider, context, error);
    } else {
      super.onOutgoingCancelled(provider, context, error);
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

  void onIncomingFinal(Context context, Object error) {
    if (_onIncomingFinal != null) {
      _onIncomingFinal(context, error);
    } else {
      super.onIncomingFinal(context, error);
    }
  }
}

/// Mock class for the [ControlledTestInterceptor]
class MockControlledTestInterceptor extends Mock
    implements ControlledTestInterceptor {}

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
  ControlledTestInterceptor()
      : super('controlled-test-interceptor-${_controlledIntCount++}');

  StreamController<RequestCompleter> _outgoingRequestStreamController =
      new StreamController();
  StreamController<RequestCompleter> _incomingRequestStreamController =
      new StreamController();
  StreamController<RequestCompleter> _incomingRejectedRequestStreamController =
      new StreamController();

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
