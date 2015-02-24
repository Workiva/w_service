part of w_service;

class UrlBased {

    Uri _uri;

    UrlBased() {
        _uri = Uri.parse('');
    }

    /**
     * Getter and setter for URL.
     */
    String get url => _uri.toString();
    void set url(String url) {
        _uri = Uri.parse(url);
    }

    /**
     * Getter and setter for URL scheme.
     */
    String get scheme => _uri.scheme;
    void set scheme(String scheme) {
        _uri = _uri.replace(scheme: scheme);
    }

    /**
     * Getter and setter for URL host.
     */
    String get host => _uri.host;
    void set host(String host) {
        _uri = _uri.replace(host: host);
    }

    /**
     * Getter and setter for URL path.
     */
    String get path => _uri.path;
    void set path(String path) {
        _uri = _uri.replace(path: path);
    }

    /**
     * Getter and setter for URL path segments.
     */
    Iterable<String> get pathSegments => _uri.pathSegments;
    void set pathSegments(Iterable<String> pathSegments) {
        _uri = _uri.replace(pathSegments: pathSegments);
    }

    /**
     * Getter and setter for URL query.
     */
    String get query => _uri.query;
    void set query(String query) {
        _uri = _uri.replace(query: query);
    }

    /**
     * Getter and setter for URL query parameters.
     */
    Map<String, String> get queryParameters => _uri.queryParameters;
    void set queryParameters(Map<String, String> queryParameters) {
        _uri = _uri.replace(queryParameters: queryParameters);
    }

    /**
     * Getter and setter for URL fragment.
     */
    String get fragment => _uri.fragment;
    void set fragment(String fragment) {
        _uri = _uri.replace(fragment: fragment);
    }

}