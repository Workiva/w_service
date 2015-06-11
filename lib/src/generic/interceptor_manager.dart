library w_service.src.generic.interceptor_manager;

import 'dart:async';

import 'context.dart';
import 'interceptor.dart';
import 'provider.dart';

/// By default, allow a maximum of 10 attempts at completing
/// the incoming interceptor chain. This allows 5 back and
/// forths between the standard and the rejected chain.
const int _defaultMaxIncomingInterceptorAttempts = 10;

/// A manager leveraged by providers to apply interceptors
/// to outgoing and incoming messages.
///
/// The manner in which interceptors are applied to messages
/// is important to know in order to understand how outgoing
/// and incoming messages are intercepted and processed.
///
/// See the [w_service wiki](https://github.com/Workiva/w_service/wiki/5.-Message-Interception)
/// for a detailed explanation with diagrams.
class InterceptorManager {

  /// Number of attempts at completing the incoming interceptor
  /// chain for each request context, keyed by context ID.
  Map<String, int> _incomingTries = {};

  /// Get and set the maximum number of cycles/attempts to allow
  /// when trying to complete the incoming interceptor chain.
  void set maxIncomingInterceptorAttempts(int max) {
    if (max <=
        0) throw new ArgumentError('Maximum interceptor attempts must be > 0');
    _maxIncomingInterceptorAttempts = max;
  }
  int get maxIncomingInterceptorAttempts => _maxIncomingInterceptorAttempts;
  int _maxIncomingInterceptorAttempts = _defaultMaxIncomingInterceptorAttempts;

  /// Intercepts an outgoing message, described by [context],
  /// from the [provider] by applying all interceptors
  /// registered with [provider] in order.
  ///
  /// Returns a Future that will complete with a [Context]
  /// instance (possibly modified/augmented) if successful.
  ///
  /// Returns a Future that will complete with an error
  /// if one of the interceptors threw an error.
  Future<Context> interceptOutgoing(Provider provider, Context context) async {
    try {
      for (int i = 0; i < provider.interceptors.length; i++) {
        context = await provider.interceptors[i].onOutgoing(provider, context);
      }
      return context;
    } catch (error) {
      for (int i = 0; i < provider.interceptors.length; i++) {
        provider.interceptors[i].onOutgoingCancelled(provider, context, error);
      }
      throw error;
    }
  }

  /// Intercepts an incoming message, described by [context],
  /// from the [provider] by applying all interceptors
  /// registered with [provider] in order.
  ///
  /// Returns a Future that will complete with a [Context]
  /// instance (possibly modified/augmented) if successful.
  ///
  /// Returns a Future that will complete with an error
  /// if one of the interceptors threw an error that could
  /// not be recovered from.
  Future<Context> interceptIncoming(Provider provider, Context context) async {
    // Keep track of the number of attempts in the incoming interceptor chain.
    _incomingTries[context.id] = 0;

    try {
      context = await interceptIncomingStandard(provider, context);

      // All interceptors resolved, meaning a stable, finalized state has been reached.
      interceptIncomingFinal(provider, context);
      return context;
    } catch (e) {
      // All interceptors rejected, meaning a stable, finalized state has been reached.
      interceptIncomingFinal(provider, context, e);
      throw e;
    }
  }

  /// Applies all interceptors registered with [provider] to
  /// the incoming message, described by [context], in order
  /// and by calling `onIncoming()` on each interceptor.
  ///
  /// Returns a Future that will complete with a [Context]
  /// instance (possibly modified/augmented) if successful.
  ///
  /// Returns a Future that will complete with an error
  /// if one of the interceptors threw an error that could
  /// not be recovered from.
  Future<Context> interceptIncomingStandard(
      Provider provider, Context context) async {
    _incomingTries[context.id]++;

    // Fail if number of tries exceeds the maximum.
    if (_incomingTries[context.id] >
        maxIncomingInterceptorAttempts) throw new MaxInterceptorAttemptsExceeded(
            '${maxIncomingInterceptorAttempts} attempts exceeded while intercepting incoming data.');

    // Apply each interceptor in order.
    try {
      for (int i = 0; i < provider.interceptors.length; i++) {
        context = await provider.interceptors[i].onIncoming(provider, context);
      }
      return context;
    } catch (error) {
      // Catch a rejection at any point in the chain and restart at the beginning
      // of the interceptor chain, but call the onIncomingRejected() interceptors methods.
      return interceptIncomingRejected(provider, context, error);
    }
  }

  /// Applies all interceptors registered with [provider] to
  /// the incoming message, described by [context], in order
  /// and by calling `onIncomingRejected()` on each interceptor.
  ///
  /// [error] describes the reason for failure.
  ///
  /// Returns a Future that will complete with a [Context]
  /// instance (possibly modified/augmented) if the error
  /// was recovered from.
  ///
  /// Returns a Future that will complete with an error
  /// if all of the interceptors threw or rethrew an error.
  Future<Context> interceptIncomingRejected(
      Provider provider, Context context, error) async {
    // Apply each interceptor in order.
    for (int i = 0; i < provider.interceptors.length; i++) {
      try {
        context = await provider.interceptors[i].onIncomingRejected(
            provider, context, error);
        // Interceptor recovered from the rejection, so restart at the beginning
        // of the interceptor chain, but call onIncoming() interceptor methods.
        return this.interceptIncomingStandard(provider, context);
      } catch (e) {
        // Interceptor did not recover, so catch the error and move on to the next.
        error = e;
      }
    }
    // All interceptors rejected (failed to recover).
    throw error;
  }

  /// Applies all interceptors registered with [provider] to
  /// the incoming message, described by [context], in order
  /// and by calling `onIncomingFinal()` on each interceptor.
  ///
  /// [error] describes the reason for failure if one occurred.
  void interceptIncomingFinal(Provider provider, Context context, [error]) {
    if (_incomingTries[context.id] != null) {
      _incomingTries.remove(context.id);
    }

    provider.interceptors.forEach((Interceptor interceptor) {
      interceptor.onIncomingFinal(context, error);
    });
  }
}

/// Exception that occurs when an [InterceptorManager] fails
/// to reach a finalized state while intercepting an incoming
/// message. This occurs when an interceptor chain repeatedly
/// rejects, and then recovers, an incoming message.
///
/// This is usually an indication of a logic bug in an
/// [Interceptor] leading to an infinite cycle.
class MaxInterceptorAttemptsExceeded implements Exception {
  MaxInterceptorAttemptsExceeded(this.message);
  final String message;
  String toString() => message;
}
