part of w_service;

typedef void _OnCancel([Error error]);
typedef Stream<ProgressEvent> _GetOnProgressStream();

class HttpFuture<HttpRequest> implements Future {

    Future<HttpRequest> _future;
    _OnCancel _onCancel;
    _GetOnProgressStream _getOnProgressStream;

    HttpFuture.from(this._future, this._onCancel, this._getOnProgressStream);

    HttpFuture<HttpRequest> then(onValue(HttpRequest value), {Function onError}) {
        return new HttpFuture.from(_future.then(onValue, onError: onError), _onCancel, _getOnProgressStream);
    }

    HttpFuture<HttpRequest> catchError(Function onError, {bool test(Object error)}) {
        return new HttpFuture.from(_future.catchError(onError, test: test), _onCancel, _getOnProgressStream);
    }

    HttpFuture<HttpRequest> whenComplete(action()) {
        return new HttpFuture.from(_future.whenComplete(action), _onCancel, _getOnProgressStream);
    }

    Stream<HttpRequest> asStream() {
        return _future.asStream();
    }

    HttpFuture<HttpRequest> timeout(Duration timeLimit, {onTimeout()}) {
        return new HttpFuture.from(_future.timeout(timeLimit, onTimeout: onTimeout), _onCancel, _getOnProgressStream);
    }

    void cancel([Error error]) {
        _onCancel(error);
    }

    Stream<ProgressEvent> get onProgress => _getOnProgressStream();

}