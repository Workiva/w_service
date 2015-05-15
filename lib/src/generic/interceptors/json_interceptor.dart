library w_service.src.generic.interceptors.json_interceptor;

import 'dart:async';
import 'dart:convert';

import '../../http/http_context.dart';
import '../context.dart';
import '../interceptor.dart';
import '../provider.dart';

class JsonInterceptor extends Interceptor {
  JsonInterceptor() : super('json', 'JSON');

  Future<Context> onOutgoing(Provider provider, Context context) async {
    if (context is HttpContext) {
      context.request.headers['Content-Type'] = 'application/json';
      if (context.request.data != null && context.request.data is! String) {
        try {
          context.request.data = JSON.encode(context.request.data);
        } catch (e) {}
      }
    }
    return context;
  }

  Future<Context> onIncoming(Provider provider, Context context) async {
    if (context is HttpContext) {
      try {
        context.response.update(JSON.decode(await context.response.asText()));
      } catch (e) {}
    }
    return context;
  }
}