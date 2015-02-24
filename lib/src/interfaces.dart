part of w_service;

/**
 * Base classes.
 */

abstract class Interceptor {
    String id;
    String name;

    Future<Context> onOutgoing(Provider provider, Context context);
    void onOutgoingCancelled(Provider provider, Context context, Error error);
    Future<Context> onIncoming(Provider provider, Context context);
    Future<Context> onIncomingRejected(Provider provider, Context context, Error error);
    void onIncomingFinal(Context context, [Error error]);
}

abstract class Provider {
    List<Interceptor> interceptors;
    void use(Interceptor interceptor);
    void useAll(List<Interceptor> interceptors);
}


/**
 * HTTP-specific classes.
 */

abstract class HttpInterceptor extends Interceptor {
    Future<HttpContext> onOutgoing(HttpProvider provider, HttpContext context);
    void onOutgoingCancelled(HttpProvider provider, HttpContext context, Error error);
    Future<HttpContext> onIncoming(HttpProvider provider, HttpContext context);
    Future<HttpContext> onIncomingRejected(HttpProvider provider, HttpContext context, Error error);
    void onIncomingFinal(HttpContext context, [Error error]);
}

abstract class HttpProviderRequest extends UrlBased {
    dynamic data;
    Map<String, String> headers;
    String method;
    String url;

    void cancel(Error error);
}

abstract class HttpProviderResponse {
    dynamic data;
    Map<String, String> get responseHeaders;
    String get responseType;
    int get status;
    String get statusText;
}

/**
 * Socket-specific classes.
 */

