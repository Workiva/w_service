library w_service.src.diagnostic.diagnosticController;

import 'package:w_service/src/diagnostic/diagnostics.dart' show Diagnostics;
import 'package:w_service/src/diagnostic/diagnostic_interceptor.dart'
    show DiagnosticInterceptor;
import 'package:w_service/src/diagnostic/diagnostic_stats.dart'
    show HttpStats, WebSocketStats;
import 'package:w_service/w_service.dart';

class ProviderDiagnostics {
  HttpStats httpStats = new HttpStats();
  Provider provider;
  WebSocketStats webSocketStats = new WebSocketStats();

  ProviderDiagnostics(Provider this.provider, Diagnostics diagnostics) {
    // Wrap a DiagnosticInterceptor around each interceptor.
    provider.interceptors = provider.interceptors.map((interceptor) {
      return new DiagnosticInterceptor(
          '${interceptor.id}-diagnostic', interceptor, diagnostics);
    }).toList();

    // Set some flags based on position in the interceptor chain
    // to enable additional diagnostic tracking.
    (provider.interceptors.first as DiagnosticInterceptor).isFirst = true;
    (provider.interceptors.last as DiagnosticInterceptor).isLast = true;
  }

  /// Restore the original state of the provider.
  /// Removes the diagnostic-only interceptors and unwraps
  /// the remaining, original interceptors.
  void restore() {
    provider.interceptors = provider.interceptors
        .map((diagnostic) => (diagnostic as DiagnosticInterceptor).interceptor)
        .toList();
  }
}
