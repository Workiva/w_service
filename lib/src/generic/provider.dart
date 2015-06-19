library w_service.src.providers.provider;

import 'package:w_service/src/generic/interceptor.dart';

/// A class used as an entry point for sending and receiving
/// data messages that handle transport-specific details.
///
/// For more detailed information, see the
/// [Provider page](https://github.com/Workiva/w_service/wiki/2.-Provider)
/// on the `w_service` wiki.
abstract class Provider {
  /// Unique identifier.
  String id;

  /// List of registered interceptors. Every interceptor in
  /// this list is applied, in order, on every outgoing and
  /// incoming message.
  List<Interceptor> interceptors = [];

  /// Construct a new instance of [Provider] with the given unique identifier.
  Provider(String this.id);

  /// Register an [Interceptor].
  void use(Interceptor interceptor) {
    interceptors.add(interceptor);
  }

  /// Register a list of [Interceptor]s in order.
  void useAll(List<Interceptor> interceptors) {
    this.interceptors.addAll(interceptors);
  }
}
