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

/// Platform agnostic library for sending and receiving data messages
/// between an application and a server with the ability to shape
/// traffic and transform data through the use of message interceptors.
@Deprecated('Use the w_transport package instead - https://github.com/Workiva/w_transport')
library w_service;

// w_transport classes.
export 'package:w_transport/w_transport.dart'
    show WHttpException, WRequest, WResponse;

// Generic classes.
export 'package:w_service/src/generic/context.dart' show Context;
export 'package:w_service/src/generic/interceptor.dart' show Interceptor;
export 'package:w_service/src/generic/interceptor_manager.dart'
    show InterceptorManager, MaxInterceptorAttemptsExceeded;
export 'package:w_service/src/generic/provider.dart' show Provider;

// Interceptors.
export 'package:w_service/src/generic/interceptors/csrf_interceptor.dart'
    show CsrfInterceptor;
export 'package:w_service/src/generic/interceptors/json_interceptor.dart'
    show JsonInterceptor;
export 'package:w_service/src/generic/interceptors/timeout_interceptor.dart'
    show TimeoutInterceptor;

// HTTP.
export 'package:w_service/src/http/http_context.dart' show HttpContext;
export 'package:w_service/src/http/http_future.dart' show HttpFuture;
export 'package:w_service/src/http/http_provider.dart'
    show HttpProvider, MaxRetryAttemptsExceeded;

// Exceptions.
export 'package:w_service/src/generic/interceptor_manager.dart'
    show MaxInterceptorAttemptsExceeded;
