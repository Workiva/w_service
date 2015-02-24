part of w_service;

class HttpException implements Exception {

    dynamic response;
    Error _error;

    HttpException.from(this._error, [this.response]);

    String toString() {
        return _error.toString();
    }

}