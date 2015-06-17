library w_service.w_service_diagnostic;

import 'dart:html';

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as react_client;
import 'package:w_service/w_service.dart';

import 'package:w_service/src/diagnostic/components/diagnostic_panel.dart'
    show DiagnosticPanel;
import 'package:w_service/src/diagnostic/diagnostics.dart' show Diagnostics;

Diagnostics _diagnostics = new Diagnostics();

/// Whether or not diagnostics are enabled.
bool _enabled = false;

void enableDiagnostics() {
  if (_enabled) return;

  react_client.setClientConfiguration();
  document.body.append(new DivElement()..id = 'w-service-diagnostics');
  var diagnosticPanel = DiagnosticPanel({'diagnostics': _diagnostics});
  react.render(diagnosticPanel, querySelector('#w-service-diagnostics'));
  _enabled = true;
}

void disableDiagnostics() {
  if (!_enabled) return;

  Element container = querySelector('#w-service-diagnostics');
  react.unmountComponentAtNode(container);
  container.remove();
  _enabled = false;
}

void watch(Provider provider) {
  _diagnostics.watch(provider);
}

void watchAll(List<Provider> providers) {
  _diagnostics.watchAll(providers);
}

void unwatch(Provider provider) {
  _diagnostics.unwatch(provider);
}

void unwatchAll(List<Provider> providers) {
  _diagnostics.unwatchAll(providers);
}
