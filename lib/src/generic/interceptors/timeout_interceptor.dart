library w_service.src.generic.interceptors.timeout_interceptor;

import 'dart:async';

import '../../http/http_context.dart';
import '../../http/http_provider.dart';
import '../context.dart';
import '../interceptor.dart';
import '../provider.dart';

class TimeoutInterceptor extends Interceptor {
  TimeoutInterceptor({Duration maxRequestDuration}) : super('timeout') {
    this._maxRequestDuration = maxRequestDuration != null
        ? maxRequestDuration
        : new Duration(seconds: 15);
  }

  Duration get maxRequestDuration => _maxRequestDuration;
  Duration _maxRequestDuration;

  Map<String, Timer> _timers = {};

  Future<Context> onOutgoing(Provider provider, Context context) async {
    if (provider is HttpProvider && context is HttpContext) {
      _timers[context.id] = new Timer(maxRequestDuration, () {
        context.meta['retryable'] = true;
        context.request.abort(new Exception(
            'Timeout threshold of ${maxRequestDuration.inSeconds.toString()} seconds exceeded.'));
        _clearTimer(context);
      });
    }
    return context;
  }

  void onOutgoingCancelled(Provider provider, Context context, Object error) {
    // Cancel the timer - request failed to send.
    _clearTimer(context);
  }

  void onIncomingFinal(Context context, Object error) {
    // Cancel the timer - request finished.
    _clearTimer(context);
  }

  void _clearTimer(Context context) {
    if (_timers.containsKey(context.id)) {
      _timers[context.id].cancel();
      _timers.remove(context.id);
    }
  }
}
