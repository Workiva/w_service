library w_service.src.generic.interceptors.timeout_interceptor;

import 'dart:async';

import '../../http/http_context.dart';
import '../../http/http_provider.dart';
import '../context.dart';
import '../interceptor.dart';
import '../provider.dart';

/// An interceptor that sets a timer for each outgoing request
/// and cancels the request if it does not complete within a
/// specified duration.
///
/// This interceptor is designed for HTTP requests and only has an
/// effect when used with the [HttpProvider].
class TimeoutInterceptor extends Interceptor {
  /// Construct a new [TimeoutInterceptor] instance.
  ///
  /// By default, the maximum request duration is 15 seconds.
  ///
  /// To override this, specify a duration upon construction:
  ///
  ///     var timeoutInterceptor =
  ///         new TimeoutInterceptor(maxRequestDuration: new Duration(seconds: 30));
  TimeoutInterceptor({Duration maxRequestDuration}) : super('timeout') {
    this._maxRequestDuration = maxRequestDuration != null
        ? maxRequestDuration
        : new Duration(seconds: 15);
  }

  /// Maximum request duration. If any request exceeds this duration
  /// before completing, it will be canceled.
  Duration get maxRequestDuration => _maxRequestDuration;
  Duration _maxRequestDuration;

  /// Map of timers for outstanding requests.
  Map<String, Timer> _timers = {};

  /// Intercepts and starts a timer for an outgoing request.
  ///
  /// If the request does not complete before the max request
  /// duration is exceeded, it will be canceled.
  @override
  Future<Context> onOutgoing(Provider provider, Context context) async {
    if (provider is HttpProvider && context is HttpContext) {
      _timers[context.id] = new Timer(maxRequestDuration, () {
        context.meta['retryable'] = true;
        context.abort(new Exception(
            'Timeout threshold of ${maxRequestDuration.inSeconds.toString()} seconds exceeded.'));
        _clearTimer(context);
      });
    }
    return context;
  }

  /// Clears the timer for a request that was canceled (was never dispatched).
  @override
  void onOutgoingCanceled(Provider provider, Context context, Object error) {
    // Cancel the timer - request failed to send.
    _clearTimer(context);
  }

  /// Clears the timer for a request that completed (successfully or not).
  @override
  void onIncomingFinal(Provider provider, Context context, Object error) {
    // Cancel the timer - request finished.
    _clearTimer(context);
  }

  /// Clears the timer for a request.
  void _clearTimer(Context context) {
    if (_timers.containsKey(context.id)) {
      _timers[context.id].cancel();
      _timers.remove(context.id);
    }
  }
}
