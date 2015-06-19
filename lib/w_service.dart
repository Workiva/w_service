/// Platform agnostic library for sending and receiving data messages
/// between an application and a server with the ability to shape
/// traffic and transform data through the use of message interceptors.
library w_service;

// TODO: Fix relative imports to use package syntax
// w_transport classes.
export 'package:w_transport/w_transport.dart' show WRequest, WResponse;

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
