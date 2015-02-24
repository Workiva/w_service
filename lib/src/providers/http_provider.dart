part of w_service;

// Constants
const int _defaultMaxRetryAttempts = 3;
const String _providerPrefix = 'httpProvider';
const String _requestPrefix = 'Req';

// HttpProvider count - allows for unique request IDs across multiple providers
int _providerCount = 0;

enum _States {
    cancelled,
    complete,
    pending,
    sent
}


class HttpProvider extends UrlBased implements Provider {

    /**
     * List of registered interceptors.
     */
    List<Interceptor> interceptors;

    /**
     * Getter and setter for URL.
     */
    Uri _url;

    /**
     * HttpRequest API.
     */
    dynamic _HttpRequest;

    /**
     * Map of IDs to HttpContexts used to track requests & responses.
     */
    Map<String, HttpContext> _contexts;

    /**
     * Request data to send on the next request.
     * Does not persist over multiple requests.
     */
    dynamic _data;

    /**
     * Request headers to send on every request.
     */
    Map<String, String> _headers;

    /**
     * Interceptor manager that applies all interceptors.
     */
    InterceptorManager _interceptorManager;

    /**
     * Maximum number of retry attempts per retry-eligible request.
     */
    int _maxRetryAttempts;

    /**
     * Meta configuration object for the next request.
     * Does not persist over multiple requests.
     * Can be used to pass information about the request
     * that may then be used by interceptors.
     */
    Map<String, dynamic> _meta;

    /**
     * Unique ID for this HTTP provider.
     */
    String _providerId;

    /**
     * Number of requests sent.
     */
    int _requestCount;

    /**
     * Whether or not to retry failed requests.
     */
    bool _shouldRetryRequests;

    HttpProvider([dynamic HttpRequest = HttpRequest, InterceptorManager interceptorManager]): super() {
        interceptors = [];

        _HttpRequest = HttpRequest;
        _contexts = new Map<String, HttpContext>();
        _data = null;
        _headers = new Map<String, String>();
        if (interceptorManager != null) {
            _interceptorManager = interceptorManager;
        } else {
            _interceptorManager = new InterceptorManager(this);
        }
        _maxRetryAttempts = _defaultMaxRetryAttempts;
        _meta = new Map<String, dynamic>();
        _providerId = _providerPrefix + (_providerCount++).toString();
        _requestCount = 0;
        _shouldRetryRequests = false;
    }

    /**
     * Register an interceptor to be applied on all outgoing
     * requests and incoming responses.
     */
    void use(Interceptor interceptor) {
        interceptors.add(interceptor);
    }

    /**
     * Register a list of interceptors to be applied on all
     * outgoing requests and incoming responses.
     */
    void useAll(List<Interceptor> interceptors) {
        interceptors.addAll(interceptors);
    }

    /**
     * Enable automatic request retrying. Will retry failed requests
     * that fit retryable criteria up to a maximum number of attempts.
     */
    void autoRetry([int numRetries = _defaultMaxRetryAttempts]) {
        if (numRetries <= 0) {
            _shouldRetryRequests = false;
            _maxRetryAttempts = 0;
        } else {
            _shouldRetryRequests = true;
            _maxRetryAttempts = numRetries;
        }
    }

    /**
     * Set the data to send on the next request.
     * This does not persist over multiple requests.
     */
    void set data(dynamic data) => _data = data;

    /**
     * Set a header.
     */
    void header(String header, String value) {
        // Remove header if empty string value given
        if (value == '' && _headers.containsKey(header)) {
            _headers.remove(header);
            return;
        }

        // Set/update header
        _headers[header] = value;
    }

    /**
     * Set one or many headers from a map.
     */
    void headers(Map<String, String> headers) {
        headers.forEach((String header, String value) => this.header(header, value));
    }

    /**
     * Update the meta configuration for the next request.
     * This does not persist over multiple requests.
     */
    void meta(Map<String, dynamic> meta) {
        meta.forEach((String key, dynamic value) {
            _meta[key] = value;
        });
    }

    /**
     * Fork the current HTTPProvider instance.
     * The returned fork will have the same URL, headers,
     * and will share the same interceptors.
     */
    HttpProvider fork() {
        HttpProvider fork = (new HttpProvider(_HttpRequest))
            ..useAll(interceptors)
            ..url = this.url
            ..headers(_headers);

        if (_shouldRetryRequests) {
            fork.autoRetry(_maxRetryAttempts);
        }
        return fork;
    }

    /**
     * Send a GET request.
     *
     * @param url
     *  If a URL is passed in, it will be used.
     *  Otherwise, the currently configured URL will be used.
     *
     * @returns an HttpFuture that behaves just like a standard Future,
     *          but is augmented to support:
     *              - cancellation via .cancel()
     */
    HttpFuture<HttpProviderResponse> get([String url]) {
        return _send('GET', url);
    }

    /**
     * Send a POST request.
     *
     * @param url
     *  If a URL is passed in, it will be used.
     *  Otherwise, the currently configured URL will be used.
     *
     * @param data
     *  If a data param is passed in, it will be used.
     *  Otherwise, the currently set data will be used (if any).
     *
     * @returns an HttpFuture that behaves just like a standard Future,
     *          but is augmented to support:
     *              - cancellation via .cancel()
     *              - progress listening via .onProgress()
     */
    HttpFuture<HttpProviderResponse> post([String url, dynamic data]) {
        return _send('POST', url, data);
    }

    /**
     * Send a PUT request.
     *
     * @param url
     *  If a URL is passed in, it will be used.
     *  Otherwise, the currently configured URL will be used.
     *
     * @param data
     *  If a data param is passed in, it will be used.
     *  Otherwise, the currently set data will be used (if any).
     *
     * @returns an HttpFuture that behaves just like a standard Future,
     *          but is augmented to support:
     *              - cancellation via .cancel()
     *              - progress listening via .onProgress()
     */
    HttpFuture<HttpProviderResponse> put([String url, dynamic data]) {
        return _send('PUT', url, data);
    }

    /**
     * Send a DELETE request.
     *
     * @param url
     *  If a URL is passed in, it will be used.
     *  Otherwise, the currently configured URL will be used.
     *
     * @returns an HttpFuture that behaves just like a standard Future,
     *          but is augmented to support:
     *              - cancellation via .cancel()
     */
    HttpFuture<HttpProviderResponse> delete([String url]) {
        return _send('DELETE', url);
    }

    /**
     * Send an upload (PUT) request.
     *
     * @param url
     *  If a URL is passed in, it will be used.
     *  Otherwise, the currently configured URL will be used.
     *
     * @param data
     *  If a data param is passed in, it will be used.
     *  Otherwise, the currently set data will be used (if any).
     *
     * @returns an HttpFuture that behaves just like a standard Future,
     *          but is augmented to support:
     *              - cancellation via .cancel()
     *              - progress listening via .onProgress()
     */
    HttpFuture<HttpProviderResponse> upload([String url, dynamic data]) {
        return _send('PUT', url, data);
    }

    /**
     * Prepare and send a request. Applies outgoing interceptors before
     * dispatching the request. Applies incoming interceptors on the response
     * before delivering that response/error to the caller via an HTTPPromise.
     */
    HttpFuture<HttpProviderResponse> _send(String method, [String url, dynamic data]) {
        if (url != null) {
            this.url = url;
        }
        if (data != null) {
            this.data = data;
        }

        // URL is required.
        if (this.url == '' || this.url == null) {
            throw new StateError('HttpProvider cannot send ' + method + ' request without a URL.');
        }

        // Data must be a valid type.
        if (this._data != null && this._data is! String && this._data is! Blob && this._data is! Document &&
            this._data is! FormData) {
            throw new ArgumentError('HTTP request data must be of type String|Blob|Document|FormData');
        }

        // HttpContext object for this request
        String id = _providerId + _requestPrefix + (_requestCount++).toString();
        HttpContext context = new HttpContext(id);

        // Dart's HttpRequest request instance, which will be available once
        // the request has actually been dispatched
        HttpRequest httpReq;

        // The interceptor chain is async, meaning the consumer may
        // continue to interact with this provider before the request
        // is dispatched. Thus, we create deep clones of the data, meta,
        // and headers at this point in time.
        dynamic reqData = JSON.decode(JSON.encode(_data));
        Map<String, String> reqHeaders = new Map.from(_headers);

        // ProgressEvent stream
        StreamController<ProgressEvent> onProgress = new StreamController<ProgressEvent>();

        // Cancel handler for the HttpFuture
        void onCancel([Error error]) {
            context.meta['state'] = _States.cancelled;
            context.meta['cancellationError'] = error;
            if (httpReq != null) {
                httpReq.abort();
            }
        }
        Stream<ProgressEvent> getOnProgressStream() {
            return onProgress.stream;
        }

        // Add to the HttpContext
        _meta.forEach((String key, dynamic value) => context.meta[key] = value);
        context.meta['state'] = _States.pending;
        context.request = new _HttpProviderRequest(method, this.url, reqData, reqHeaders, onCancel);

        // Initialize/increment # of attempts
        if (_shouldRetryRequests && !context.meta.containsKey('retryable')) {
            context.meta['retryable'] = _shouldRetryRequests;
            context.meta['attempts'] = 0;
        } else if (context.meta['retryable']) {
            context.meta['attempts']++;
        }

        // Bail if request attempts exceeds to maximum
        if (context.meta['retryable'] && context.meta['attempts'] > _maxRetryAttempts) {
            _cleanup(context);
            return new Future.error(new Exception('Max retry attempts exceeded.'));
        }

        // Store context until completed
        _contexts[context.id] = context;

        // Kick off the chain of async events involved in sending a request
        // 1. Apply outgoing interceptors
        Future<HttpContext> contextFuture = _interceptorManager.interceptOutgoing(context);
        contextFuture = contextFuture.then((HttpContext context) {
            // Check for cancellation
            if (context.meta['state'] == _States.cancelled) {
                _cleanup(context);
                return new Future.error(context.meta['cancellationError']);
            }

            // 2. Dispatch request
            httpReq = _dispatch(context);
            httpReq.onProgress.listen(onProgress.add);
            return httpReq.onLoad.single.then((_) {
                // Update context with response.
                context.response = new _HttpProviderResponse(httpReq.response, httpReq.responseHeaders,
                                                             httpReq.responseType, httpReq.status, httpReq.statusText);
                return new Future.value(context);
            });
        }).then((HttpContext context) {
            // Check for cancellation
            if (context.meta['state'] == _States.cancelled) {
                _cleanup(context);
                return new Future.error(context.meta['cancellationError']);
            }

            // 3. Receive response, apply incoming interceptors.
            return _interceptorManager.interceptIncoming(context);
        });

        Future<HttpProviderResponse> responseFuture = contextFuture.then((HttpContext context) {
            // Check for cancellation
            if (context.meta['state'] == _States.cancelled) {
                _cleanup(context);
                return new Future.error(context.meta['cancellationError']);
            }

            // 4. Return response and cleanup state
            _cleanup(context);
            return new Future.value(context.response);
        }).catchError((Error error) {
            // Check to see if the failure is retryable.
            if (_shouldRetryRequests && HttpProvider._isRetryable(context)) {
                // Attempt a retry before giving up.
                return _retry(context).then((HttpProviderResponse response) {
                    // Retry eventually succeeded.
                    _cleanup(context);
                    return new Future.value(response);
                }).catchError((Error error) {
                    _cleanup(context);
                    return new Future.error(new HttpException.from(error, context.response));
                });
            } else {
                _cleanup(context);
                return new Future.error(new HttpException.from(error, context.response));
            }
        });

        // Create and return an HttpFuture from the future chain we've setup.
        return new HttpFuture.from(responseFuture, onCancel, getOnProgressStream);
    }

    /**
     * Create and send an HttpRequest (XHR).
     */
    HttpRequest _dispatch(HttpContext context) {
        HttpRequest req = new HttpRequest()
            ..open(context.request.method, context.request.url, async: true)
            ..withCredentials = true;

        context.request.headers.forEach(req.setRequestHeader);
        req.send(context.request.data);
        return req;
    }

    /**
     * Determine if a failed request is retryable based on the
     * status code and response data.
     */
    static bool _isRetryable(HttpContext context) {
        if (context.response == null) {
            return false;
        }
        bool isPotentiallyTransientFailure = context.response.status == 500 || context.response.status == 502;
        bool isCsrfFailure = context.response.status == 403 && context.response.data.indexOf('CSRF Failure') > -1;
        return isPotentiallyTransientFailure || isCsrfFailure;
    }

    /**
     * Retry a failed request.
     */
    HttpFuture<HttpProviderResponse> _retry(HttpContext context) {
        HttpProvider fork = this.fork();
        fork..data = context.request.data
            ..headers(context.request.headers)
            ..meta(context.meta)
            ..url = context.request.url;

        Future<HttpProviderResponse> future;

        switch (context.request.method) {
            case 'GET':
                future = fork.get();
                break;
            case 'POST':
                future = fork.post();
                break;
            case 'PUT':
                future = fork.put();
                break;
            case 'DELETE':
                future = fork.delete();
                break;
        }

        future = future.then((HttpProviderResponse response) {
            // Retry eventually succeeded, update the response.
            context.response = response;
            return new Future.value(context);
        });

        return future;
    }

    /**
     * Cleanup state for a now-completed request context.
     */
    void _cleanup(HttpContext context) {
        if (context.meta['state'] == _States.cancelled) {
            context.meta['state'] = _States.complete;
        }

        if (_contexts.containsKey(context.id)) {
            _contexts.remove(context.id);
        }
    }

}

class _HttpProviderRequest extends UrlBased implements HttpProviderRequest {

    dynamic data;
    Map<String, String> headers;
    String method;
    _OnCancel _onCancel;

    _HttpProviderRequest(this.method, String url, this.data, this.headers, this._onCancel) {
        this.url = url;
    }

    void cancel([Error error]) {
        _onCancel(error);
    }

}

class _HttpProviderResponse implements HttpProviderResponse {

    dynamic data;

    Map<String, String> _responseHeaders;
    Map<String, String> get responseHeaders => _responseHeaders;

    String _responseType;
    String get responseType => _responseType;

    int _status;
    int get status => _status;

    String _statusText;
    String get statusText => _statusText;

    _HttpProviderResponse(this.data, this._responseHeaders, this._responseType, this._status, this._statusText);

}
