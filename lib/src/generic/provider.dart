library w_service.src.providers.provider;

import 'interceptor.dart';

///
abstract class Provider {
  /// List of registered interceptors. Every interceptor in
  /// this list is applied, in order, on every outgoing and
  /// incoming message.
  List<Interceptor> interceptors = [];

  /// Register an [Interceptor].
  void use(Interceptor interceptor) {
    interceptors.add(interceptor);
  }

  /// Register a list of [Interceptor]s in order.
  void useAll(List<Interceptor> interceptors) {
    this.interceptors.addAll(interceptors);
  }
}
