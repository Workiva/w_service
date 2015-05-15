library w_service.src.generic.interceptors.timeout_interceptor;

import 'dart:async';

import '../../http/http_context.dart';
import '../../http/http_provider.dart';
import '../context.dart';
import '../interceptor.dart';
import '../provider.dart';

class TimeoutInterceptor extends Interceptor {
  TimeoutInterceptor({Duration maxRequestDuration}) : super('timeout', 'Timeout') {
    _maxRequestDuration = maxRequestDuration != null ? maxRequestDuration : new Duration(seconds: 15);
  }

  Duration _maxRequestDuration;

  Map<String, Timer> _timers = {};

  Future<Context> onOutgoing(Provider provider, Context context) async {
    if (provider is HttpProvider && context is HttpContext) {
      _timers[context.id] = new Timer(_maxRequestDuration, () {
        context.meta['retryable'] = true;
        // TODO: provider won't know about this cancellation
        context.request.abort();
        _clearTimer(context);
        // TODO: this will throw in a random async zone.. how will that look?
        throw new Exception('Timeout threshold of ${_maxRequestDuration.inSeconds.toString()} seconds exceeded.');
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
