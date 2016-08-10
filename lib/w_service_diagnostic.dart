// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
@Deprecated('Use the w_transport package instead - https://github.com/Workiva/w_transport')
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
