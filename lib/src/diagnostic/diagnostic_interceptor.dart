library w_service.src.diagnostic.diagnostic_interceptor;

import 'dart:async';

import 'package:w_service/src/diagnostic/diagnostics.dart' show Diagnostics;
import 'package:w_service/w_service.dart';

class DiagnosticInterceptor extends Interceptor {
  DiagnosticInterceptor(
      String id, Interceptor this.interceptor, Diagnostics this.diagnostics)
      : super(id);

  Diagnostics diagnostics;
  bool isFirst = false;
  bool isLast = false;
  Interceptor interceptor;

  @override
  Future<Context> onOutgoing(Provider provider, Context context) async {
    diagnostics.messageMap.update(provider, this, context, 'outgoing');
    if (isFirst) {
      context.meta['providerId'] = provider.id;
      if (context is HttpContext) {
        if (context.meta.containsKey('attempts') &&
            context.meta['attempts'] > 0) {
          diagnostics.providerDiagnostics[provider].httpStats.retries++;
        }
      }
    }

    if (diagnostics.shouldControlFor(provider)) {
      print('awaiting control');
      await diagnostics.control(context);
      print('control gained');
    }

    context = await interceptor.onOutgoing(provider, context);

    if (isLast) {
      if (context is HttpContext) {
        diagnostics.messageMap.markAsPending(context);
      }
    }
    return context;
  }

  @override
  void onOutgoingCancelled(Provider provider, Context context, Object error) {
    diagnostics.messageMap.update(provider, this, context, 'outgoingCancelled');
    if (isFirst) {
      context.meta['error'] = error;
      // TODO: remove this once request cancellation info is available on HttpContext
      context.meta['cancelled'] = true;

      if (context is HttpContext) {
        diagnostics.providerDiagnostics[provider].httpStats.failures++;
      }
    }
    interceptor.onOutgoingCancelled(provider, context, error);
    if (isLast) {
      diagnostics.messageMap.markAsComplete(context);
    }
  }

  @override
  Future<Context> onIncoming(Provider provider, Context context) async {
    diagnostics.messageMap.update(provider, this, context, 'incoming');

    if (isFirst) {
      context.meta['providerId'] = provider.id;
    }

    if (diagnostics.shouldControlFor(provider)) {
      await diagnostics.control(context);
    }

    context = await interceptor.onIncoming(provider, context);
    return context;
  }

  @override
  Future<Context> onIncomingRejected(
      Provider provider, Context context, Object error) async {
    diagnostics.messageMap.update(provider, this, context, 'incomingRejected');
    context.meta['error'] = error;

    if (isFirst) {
      context.meta['providerId'] = provider.id;
    }

    if (diagnostics.shouldControlFor(provider)) {
      await diagnostics.control(context);
    }

    try {
      context = await interceptor.onIncomingRejected(provider, context, error);
      return context;
    } catch (e) {
      throw e;
    }
  }

  @override
  void onIncomingFinal(Provider provider, Context context, Object error) {
    diagnostics.messageMap.update(provider, this, context, 'incomingFinal');

    if (isFirst) {
      context.meta['error'] = error;

      if (context is HttpContext) {
        if (context.response.status >= 200 && context.response.status < 300) {
          diagnostics.providerDiagnostics[provider].httpStats.successes++;
        } else {
          diagnostics.providerDiagnostics[provider].httpStats.failures++;
        }
      }
    }
    interceptor.onIncomingFinal(provider, context, error);

    if (isLast) {
      diagnostics.messageMap.markAsComplete(context);
    }
  }
}
