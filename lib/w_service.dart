/// Platform agnostic library for sending and receiving data messages
/// between an application and a server with the ability to shape
/// traffic and transform data through the use of message interceptors.
library w_service;

// TODO: Fix relative imports to use package syntax
// w_transport classes.
export 'package:w_transport/w_transport.dart' show WRequest, WResponse;

// Generic classes.
export 'src/generic/context.dart' show Context;
export 'src/generic/interceptor.dart' show Interceptor;
export 'src/generic/interceptor_manager.dart'
    show InterceptorManager, MaxInterceptorAttemptsExceeded;
export 'src/generic/provider.dart' show Provider;

// Interceptors.
export 'src/generic/interceptors/csrf_interceptor.dart' show CsrfInterceptor;
export 'src/generic/interceptors/json_interceptor.dart' show JsonInterceptor;
export 'src/generic/interceptors/timeout_interceptor.dart'
    show TimeoutInterceptor;

// HTTP.
export 'src/http/http_context.dart' show HttpContext;
export 'src/http/http_future.dart' show HttpFuture;
export 'src/http/http_provider.dart'
    show HttpProvider, MaxRetryAttemptsExceeded;

// Exceptions.
export 'src/generic/interceptor_manager.dart'
    show MaxInterceptorAttemptsExceeded;
