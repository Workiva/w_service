// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
