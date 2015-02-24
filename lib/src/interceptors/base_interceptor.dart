part of w_service;

class BaseInterceptor implements Interceptor {

    String id;
    String name;

    BaseInterceptor() {
        id = 'base';
        name = 'Base';
    }

    Future<Context> onOutgoing(Provider provider, Context context) => new Future.value(context);
    void onOutgoingCancelled(Provider provider, Context context, Error error) {}
    Future<Context> onIncoming(Provider provider, Context context) => new Future.value(context);
    Future<Context> onIncomingRejected(Provider provider, Context context, Error error) => new Future.error(error);
    void onIncomingFinal(Context context, [Error error]) {}

}