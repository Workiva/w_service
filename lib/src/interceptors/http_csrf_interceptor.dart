part of w_service;

String _csrfTokenHeader = 'X-XSRF-TOKEN';

class HttpCsrfInterceptor extends BaseInterceptor implements HttpInterceptor {

    String id;
    String name;

    static String _nextToken;

    HttpCsrfInterceptor() {
        id = 'csrf';
        name = 'CSRF';
    }

    String get token => HttpCsrfInterceptor._nextToken;
    void set token(String token) {
        HttpCsrfInterceptor._nextToken = token;
    }

    Future<HttpContext> onOutgoing(HttpProvider provider, HttpContext context) {
        // Inject CSRF token into request headers.
        context.request.headers[_csrfTokenHeader] = HttpCsrfInterceptor._nextToken;
        return new Future.value(context);
    }

    Future<HttpContext> onIncoming(HttpProvider provider, HttpContext context) {
        // Retrieve next token from response headers.
        HttpCsrfInterceptor._updateTokenFromResponse(context.response);
        return new Future.value(context);
    }

    Future<HttpContext> onIncomingRejected(HttpProvider provider, HttpContext context, Error error) {
        // Retrieve next token from response headers.
        HttpCsrfInterceptor._updateTokenFromResponse(context.response);
        return new Future.error(error);
    }

    static void _updateTokenFromResponse(HttpProviderResponse response) {
        if (response.responseHeaders.containsKey(_csrfTokenHeader)) {
            HttpCsrfInterceptor._nextToken = response.responseHeaders[_csrfTokenHeader];
        }
    }

}