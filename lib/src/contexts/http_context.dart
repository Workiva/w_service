part of w_service;

class HttpContext extends Context {

    HttpProviderRequest request;
    HttpProviderResponse response;

    HttpContext(String id): super(id);

}