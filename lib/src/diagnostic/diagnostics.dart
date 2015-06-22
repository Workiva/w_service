library w_service.src.diagnostic.diagnostics;

import 'dart:async';

import 'package:w_service/src/diagnostic/diagnostic_stats.dart'
    show HttpStats, WebSocketStats;
import 'package:w_service/src/diagnostic/provider_diagnostics.dart'
    show ProviderDiagnostics;
import 'package:w_service/w_service.dart';

class Diagnostics {
  List<Provider> controlledFor = [];
  MessageMap messageMap;
  Map<Provider, ProviderDiagnostics> providerDiagnostics = {};

  Map<Context, Completer> _pending = {};
  StreamController<List<ProviderDiagnostics>> _providerDiagnosticsStreamController;
  Stream<List<ProviderDiagnostics>> _providerDiagnosticsStream;

  Diagnostics() {
    messageMap = new MessageMap();

    _providerDiagnosticsStreamController = new StreamController();
    _providerDiagnosticsStream =
        _providerDiagnosticsStreamController.stream.asBroadcastStream();
  }

  HttpStats get httpStats {
    HttpStats stats = new HttpStats();
    providerDiagnostics.values.forEach((providerDiagnostics) {
      stats.failures += providerDiagnostics.httpStats.failures;
      stats.retries += providerDiagnostics.httpStats.retries;
      stats.successes += providerDiagnostics.httpStats.successes;
    });
    return stats;
  }

  Stream<List<ProviderDiagnostics>> get providerDiagnosticsStream =>
      _providerDiagnosticsStream;

  WebSocketStats get webSocketStats {
    WebSocketStats stats = new WebSocketStats();
    providerDiagnostics.values.forEach((providerDiagnostics) {
      stats.failures += providerDiagnostics.webSocketStats.failures;
      stats.successes += providerDiagnostics.webSocketStats.successes;
    });
    return stats;
  }

  void advance(Context context) {
    _pending[context].complete();
  }

  Future control(Context context) {
    _pending[context] = new Completer();
    return _pending[context].future;
  }

  void controlFor(Provider provider) {
    if (controlledFor.contains(provider)) return;
    controlledFor.add(provider);
  }

  void releaseControlFor(Provider provider) {
    if (!controlledFor.contains(provider)) return;
    controlledFor.remove(provider);
  }

  bool shouldControlFor(Provider provider) {
    return controlledFor.contains(provider);
  }

  void watch(Provider provider) {
    if (providerDiagnostics.containsKey(provider)) return;

    providerDiagnostics[provider] = new ProviderDiagnostics(provider, this);
    messageMap.messages[provider] = {};
    provider.interceptors.forEach((interceptor) {
      messageMap.messages[provider][interceptor] = {
        'outgoing': {},
        'outgoingCanceled': {},
        'incoming': {},
        'incomingRejected': {},
        'incomingFinal': {}
      };
    });
    _updateProviderDiagnosticsStream();
  }

  void watchAll(List<Provider> providers) {
    providers.forEach(watch);
  }

  void unwatch(Provider provider) {
    if (!providerDiagnostics.containsKey(provider)) return;

    provider.interceptors.forEach((interceptor) {
      messageMap.messages.remove(provider);
    });
    providerDiagnostics[provider].restore();
    providerDiagnostics.remove(provider);
    _updateProviderDiagnosticsStream();
  }

  void unwatchAll(List<Provider> providers) {
    providers.forEach(unwatch);
  }

  void _updateProviderDiagnosticsStream() {
    _providerDiagnosticsStreamController
        .add(providerDiagnostics.values.toList());
  }
}

class MessageMap {
  List<Context> complete = [];
  List<Context> detailed = [];
  Map<Provider, Map<Interceptor, Map<String, Map<String, Context>>>> messages =
      {};
  List<Context> pending = [];
  List<Context> recent = [];

  Map<Context, _Location> _locations = {};
  Stream<MessageMap> _stream;
  StreamController<MessageMap> _streamController;

  MessageMap() {
    _streamController = new StreamController();
    _stream = _streamController.stream.asBroadcastStream();
  }

  Stream<MessageMap> get stream => _stream;

  void closeDetailsFor(Context context) {
    if (detailed.contains(context)) {
      detailed.remove(context);
      _updateStream();
    }
  }

  void markAsComplete(Context context) {
    if (_locations.containsKey(context)) {
      _Location loc = _locations[context];
      messages[loc.provider][loc.interceptor][loc.step].remove(context.id);
    }
    complete.add(context);
    _updateStream();
  }

  void markAsPending(Context context) {
    if (_locations.containsKey(context)) {
      _Location loc = _locations[context];
      messages[loc.provider][loc.interceptor][loc.step].remove(context.id);
    }
    pending.add(context);
    _updateStream();
  }

  List<Context> messagesAt(
      Provider provider, Interceptor interceptor, String step) {
    return messages[provider][interceptor][step].values.toList();
  }

  void update(Provider provider, Interceptor interceptor, Context context,
      String step) {
    if (_locations.containsKey(context)) {
      // Updating a previously added message
      _Location loc = _locations[context];
      messages[loc.provider][loc.interceptor][loc.step].remove(context.id);
    } else {
      // Adding a brand new message
      List<Context> newRecent = new List.from(recent.reversed);
      newRecent.add(context);
      recent = newRecent.reversed.take(10).toList();
    }
    _locations[context] = new _Location(provider, interceptor, step);
    messages[provider][interceptor][step][context.id] = context;

    if (pending.contains(context)) {
      pending.remove(context);
    }
    _updateStream();
  }

  void viewDetailsFor(Context context) {
    if (!detailed.contains(context)) {
      detailed.add(context);
      _updateStream();
    }
  }

  void _updateStream() {
    _streamController.add(this);
  }
}

class _Location {
  Provider provider;
  Interceptor interceptor;
  String step;
  _Location(this.provider, this.interceptor, this.step);
}
