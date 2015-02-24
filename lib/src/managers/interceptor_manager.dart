part of w_service;

// Maximum number of cycles/attempts to allow when trying to complete
// the incoming interceptor chain.
const int _defaultMaxIncomingAttempts = 10;

class InterceptorManager {

    // Map to hold the number of attempts at completing the incoming
    // interceptor chain for each context ID.
    Map<String, int> _incomingAttempts;

    // Maximum number of attempts to allow for the incoming interceptor chain.
    int _maxIncomingAttempts;

    // Provider for which interceptors are being managed.
    Provider _provider;


    InterceptorManager(this._provider) {
        _incomingAttempts = new Map<String, int>();
        _maxIncomingAttempts = _defaultMaxIncomingAttempts;
    }

    void set maxIncomingAttempts(int max) { _maxIncomingAttempts = max; }

    Future<Context> interceptOutgoing(Context context) {
        // Apply each interceptor using a future chain.
        Future<Context> future = new Future.value(context);
        _provider.interceptors.forEach((Interceptor interceptor) {
            future = future.then((Context context) {
                return interceptor.onOutgoing(_provider, context);
            });
        });

        // TODO - THIS COULD BREAK SHIT (future = future.catchError(...))
        // Catch an error at any point in the chain.
        future = future.catchError((Error error) {
            // Apply all onOutgoingCancelled() interceptors.
            _provider.interceptors.forEach((Interceptor interceptor) {
                interceptor.onOutgoingCancelled(_provider, context, error);
            });
        });

        return future;
    }

    Future<Context> interceptIncoming(Context context) {
        // Keep track of number of attempts in the incoming interceptor chain.
        _incomingAttempts[context.id] = 0;

        Future<Context> future = interceptIncomingStandard(context);

        // If all interceptors resolved, we are in a stable, finalized state.
        future.then((Context context) {
            interceptIncomingFinal(context);
        });

        // If all interceptors rejected, we are in a stable, finalized state.
        future.catchError((Error error) {
            interceptIncomingFinal(context, error);
        });

        return future;
    }

    Future<Context> interceptIncomingStandard(Context context) {
        _incomingAttempts[context.id]++;

        Future<Context> future;

        // Fail if number of attempts exceeds the maximum.
        if (_incomingAttempts[context.id] > _maxIncomingAttempts) {
            Exception exception = new Exception('Max number of attempts exceeded while intercepting incoming data.');
            future = new Future.error(exception);
            interceptIncomingFinal(context, exception);
            return future;
        }

        // Apply each interceptor using a promise chain.
        future = new Future.value(context);
        _provider.interceptors.forEach((Interceptor interceptor) {
            future = future.then((Context context) {
                return interceptor.onIncoming(_provider, context);
            });
        });

        // Catch an error at any point in the chain.
        future = future.catchError((Error error) {
            // Restart at the beginning of the interceptor chain,
            // but call the onIncomingRejected() interceptors.
            return interceptIncomingRejected(context, error);
        });

        return future;
    }

    Future<Context> interceptIncomingRejected(Context context, Error error) {
        // Apply each rejected interceptor using a future chain.
        Future<Context> future = new Future.error(error);
        _provider.interceptors.forEach((Interceptor interceptor) {
            // This chain is different in that a resolving promise will recover
            // from the error, whereas another error will be a continuation.
            future = future.catchError((Error error) {
                return interceptor.onIncomingRejected(_provider, context, error);
            });
        });

        // Catch a recovery (resolve) at any point in the chain.
        future = future.then((Context context) {
            // Restart at the beginning of the interceptor chain,
            // once again calling the standard onIncoming() interceptors.
            return interceptIncomingStandard(context);
        });

        return future;
    }

    void interceptIncomingFinal(Context context, [Object error]) {
        // Cleanup state
        if (_incomingAttempts.containsKey(context.id)) {
            _incomingAttempts.remove(context.id);
        }

        // Apply all onIncomingFinal() interceptors
        _provider.interceptors.forEach((Interceptor interceptor) {
            interceptor.onIncomingFinal(context, error);
        });
    }

}