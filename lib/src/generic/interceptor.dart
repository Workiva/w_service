library w_service.src.generic.interceptor;

import 'dart:async';

import 'context.dart';
import 'provider.dart';

abstract class Interceptor {
  /// Construct a new [Interceptor] instance.
  Interceptor(String id) : this.id = id;

  /// Unique identifier.
  final String id;

  Future<Context> onOutgoing(Provider provider, Context context) async {
    return context;
  }

  void onOutgoingCancelled(Provider provider, Context context, Object error) {}

  Future<Context> onIncoming(Provider provider, Context context) async {
    return context;
  }

  Future<Context> onIncomingRejected(
      Provider provider, Context context, Object error) async {
    throw error;
  }

  void onIncomingFinal(Context context, Object error) {}
}
