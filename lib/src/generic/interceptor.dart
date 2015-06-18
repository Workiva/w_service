library w_service.src.generic.interceptor;

import 'dart:async';

import 'package:w_service/src/generic/context.dart';
import 'package:w_service/src/generic/provider.dart';

/// A class used to intercept outgoing and incoming messages.
/// Purposes include message preparation, data transformation,
/// traffic shaping, and error handling.
///
/// An [Interceptor] is used by a [Provider], and a [Provider]
/// can have multiple [Interceptor]s. [Provider]s use the
/// [InterceptorManager] to apply these [Interceptor]s to every
/// message.
///
/// For more detailed information, see the
/// [Interceptor page](https://github.com/Workiva/w_service/wiki/3.-Interceptor)
/// on the w_service wiki.
///
/// For a detailed explanation of the flow of messages through
/// interceptors, see the
/// [InterceptorManager page](https://github.com/Workiva/w_service/wiki/4.-InterceptorManager)
/// on the w_service wiki.
///
/// It is likely that an [Interceptor] will be designed for a
/// particular [Provider]. In those cases, it is expected that
/// type checking occur on the [provider] or the [context] in
/// order to assume more information about the objects.
///
/// For example, an interceptor designed for the [HttpProvider]
/// would check the [context] to see if it's an instance of
/// [HttpContext] so that it can access additional properties.
///
///     Future<Context> onOutgoing(Provider provider, Context context) async {
///         if (context is HttpContext) {
///             print('${context.request.uri}');
///         }
///     }
abstract class Interceptor {
  /// Construct a new [Interceptor] instance.
  ///
  /// The [id] should be unique among all interceptors.
  /// If appropriate, use a namespace prefix.
  Interceptor(String id) : this.id = id;

  /// Unique identifier.
  final String id;

  /// Intercepts an outgoing message from the [provider].
  ///
  /// May be called once or not at all for each message.
  /// See [InterceptorManager] for more information.
  ///
  /// The [context] includes all relevant information about
  /// the message and is free to be modified or augmented.
  ///
  /// This should be overridden by a subclass in order to
  /// perform some action on every outgoing message.
  ///
  /// If this returns a Future that completes with the context,
  /// the message will continue through the interceptor chain
  /// to eventually be dispatched.
  ///
  ///     Future<Context> onOutgoing(Provider provider, Context context) async {
  ///       ...
  ///       return context;
  ///     }
  ///
  /// If this returns a Future that completes with an error,
  /// the message will be cancelled and will not be dispatched.
  ///
  ///     Future<Context> onOutgoing(Provider provider, Context context) async {
  ///       ...
  ///       throw new Exception('...');
  ///     }
  ///
  /// By default, this returns a Future that completes with
  /// the same context.
  Future<Context> onOutgoing(Provider provider, Context context) async {
    return context;
  }

  /// Intercepts an outgoing message from the [provider] that
  /// has been cancelled due to an error in the `onOutgoing`
  /// interceptor chain. See [InterceptorManager] for more
  /// information.
  ///
  /// This will be called exactly once for every outgoing message
  /// that fails to be dispatched due to an error in the
  /// `onOutgoing` interceptor chain.
  ///
  /// The [context] includes all relevant information about the message.
  ///
  /// This method is essentially just a callback for notification
  /// purposes, so nothing needs to be returned.
  ///
  /// By default, this does nothing.
  void onOutgoingCancelled(Provider provider, Context context, Object error) {}

  /// Intercepts an incoming message from the [provider].
  ///
  /// May be called once, multiple times, or not at all for
  /// each message. See [InterceptorManager] for more information.
  ///
  /// The [context] includes all relevant information about
  /// the message and is free to be modified or augmented.
  ///
  /// This should be overridden by a subclass in order to
  /// perform some action on every incoming message.
  ///
  /// If this returns a Future that completes with the context,
  /// the message will continue through the interceptor chain
  /// to eventually be returned to the caller.
  ///
  ///     Future<Context> onIncoming(Provider provider, Context context) async {
  ///       ...
  ///       return context;
  ///     }
  ///
  /// If this returns a Future that completes with an error,
  /// the message will be rejected. The message will then be
  /// processed by `onIncomingRejected` and at that point the
  /// rejection could be recovered from.
  ///
  ///     Future<Context> onIncoming(Provider provider, Context context) async {
  ///       ...
  ///       throw new Exception('...');
  ///     }
  ///
  /// By default, this returns a Future that completes with
  /// the same context.
  Future<Context> onIncoming(Provider provider, Context context) async {
    return context;
  }

  /// Intercepts an incoming message from the [provider] that
  /// has been rejected.
  ///
  /// May be called once, multiple times, or not at all for
  /// each message. See [InterceptorManager] for more information.
  ///
  /// The [context] includes all relevant information about
  /// the message.
  ///
  /// The [error] is the error that was thrown that caused the
  /// rejection.
  ///
  /// This should be overridden by a subclass in order to
  /// perform some action on every incoming message that gets
  /// rejected.
  ///
  /// If this returns a Future that completes with an error,
  /// the message will remain in its rejected state.
  ///
  ///     Future<Context> onIncomingRejected(Provider provider, Context context, Object error) async {
  ///       throw error;
  ///     }
  ///
  /// If this returns a Future that completes with the context,
  /// the message will "recover" from the rejection. The message
  /// will then once again be processed by `onIncoming`.
  ///
  ///     Future<Context> onIncomingRejected(Provider provider, Context context, Object error) async {
  ///       return context;
  ///     }
  ///
  /// By default, this rethrows the error so the message remains
  /// in the same rejected state.
  Future<Context> onIncomingRejected(
      Provider provider, Context context, Object error) async {
    throw error;
  }

  /// Intercepts an incoming message from the [provider] after
  /// it has reached a finalized state (either successful or rejected).
  ///
  /// This will be called exactly once for every incoming message,
  /// which is useful for cleaning up state, logging, or
  /// analytics.
  ///
  /// This should be overridden by a subclass in order to
  /// perform some action on every incoming message, exactly
  /// once.
  ///
  /// By default, this does nothing.
  void onIncomingFinal(Provider provider, Context context, Object error) {}
}
