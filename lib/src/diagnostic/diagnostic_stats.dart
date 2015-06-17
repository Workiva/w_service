library w_service.src.diagnostic.diagnostic_stats;

class _TransportStats {
  int failures = 0;
  int successes = 0;
  double get successRate =>
      total > 0 ? successes.toDouble() / total * 100 : 100.0;
  int get total => failures + successes;
}

class HttpStats extends _TransportStats {
  int retries = 0;
}

class WebSocketStats extends _TransportStats {}
