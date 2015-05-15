library w_service.src.generic.interceptor_manager;

import 'dart:async';

import 'context.dart';
import 'interceptor.dart';
import 'provider.dart';

/// By default, allow a maximum of 10 attempts at completing
/// the incoming interceptor chain. This allows 5 back and
/// forths between the standard and the rejected chain.
const int _defaultMaxIncomingInterceptorAttempts = 10;

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

  Future<Context> interceptIncoming(Provider provider, Context context,
      [error]) async {
    // Keep track of the number of attempts in the incoming interceptor chain.
    _incomingTries[context.id] = 0;

    try {
      if (error == null) {
        // No error, so start with the standard incoming interceptors.
        context = await interceptIncomingStandard(provider, context);
      } else {
        // Error, start with the incoming rejected interceptors.
        context = await interceptIncomingRejected(provider, context, error);
      }

      // All interceptors resolved, meaning a stable, finalized state has been reached.
      interceptIncomingFinal(provider, context);
      return context;
    } catch (e) {
      // All interceptors rejected, meaning a stable, finalized state has been reached.
      interceptIncomingFinal(provider, context, e);
      throw e;
    }
  }

  Future<Context> interceptIncomingStandard(
      Provider provider, Context context) async {
    _incomingTries[context.id]++;

    // Fail if number of tries exceeds the maximum.
    if (_incomingTries[context.id] >
        maxIncomingInterceptorAttempts) throw new MaxInterceptorAttemptsExceededException(
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

  void interceptIncomingFinal(Provider provider, Context context, [error]) {
    if (_incomingTries[context.id] != null) {
      _incomingTries.remove(context.id);
    }

    provider.interceptors.forEach((Interceptor interceptor) {
      interceptor.onIncomingFinal(context, error);
    });
  }
}

class MaxInterceptorAttemptsExceededException implements Exception {
  MaxInterceptorAttemptsExceededException(this.message);
  final String message;
  String toString() => message;
}
