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

library w_service.src.http.http_context;

import 'package:w_transport/w_transport.dart';

import 'package:w_service/src/generic/context.dart';

int _count = 0;
const String _idPrefix = 'http-context-';

/// Creates a new [HttpContext] instance.
/// This is used internally but is not exported,
/// allowing the [HttpContext] class to be exported
/// without allowing new instances of it to be constructed,
/// since that should not be necessary.
HttpContext httpContextFactory() => new HttpContext._();

/// Context for service messages sent over HTTP.
/// In addition to the properties on [Context],
/// [HttpContext] includes [request] and [response]
/// properties that are specific to HTTP transport.
class HttpContext extends Context {
  // TODO: this is a stop-gap, will be replaced by a real method.
  var abort;

  /// [w_transport](https://github.com/Workiva/w_transport)
  /// WRequest object used to send the HTTP request.
  WRequest request;

  /// [w_transport](https://github.com/Workiva/w_transport)
  /// WResponse object representing the response to the request.
  WResponse response;

  /// Construct a new [HttpContext] instance.
  /// The [request] and [response] properties should be
  /// populated as they become available.
  HttpContext._() : super('$_idPrefix${_count++}');
}
