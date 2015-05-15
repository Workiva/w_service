library w_service.src.generic.interceptor;

import 'dart:async';

import 'context.dart';
import 'provider.dart';

abstract class Interceptor {
  /// Construct a new [Interceptor] instance.
  Interceptor(String id, [String name])
      : this.id = id,
        this.name = name != null ? name : id;

  /// Unique identifier.
  final String id;

  /// Readable identifier.
  final String name;

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
