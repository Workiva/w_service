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

library w_service.src.diagnostic.components.provider_panel;

import 'package:react/react.dart' as react;

import 'package:w_service/src/diagnostic/components/collapsible_panel.dart'
    show CollapsiblePanel;
import 'package:w_service/src/diagnostic/components/message.dart' show Message;
import 'package:w_service/src/diagnostic/diagnostics.dart' show Diagnostics;
import 'package:w_service/src/diagnostic/provider_diagnostics.dart'
    show ProviderDiagnostics;
import 'package:w_service/w_service.dart';

var ProviderPanel = react.registerComponent(() => new _ProviderPanel());
class _ProviderPanel extends react.Component {
  bool get controllable => state['controllable'];
  Diagnostics get diagnostics => props['diagnostics'];
  Function get onExpandMessage => props['onExpandMessage'];
  ProviderDiagnostics get providerDiagnostics => props['providerDiagnostics'];

  getDefaultProps() => {
    'diagnostics': null,
    'onAdvanceMessage': (_) {},
    'onExpandMessage': (_) {},
    'providerDiagnostics': null
  };

  getInitialState() => {'controllable': false};

  render() {
    if (diagnostics == null || providerDiagnostics == null) return '';
    var controls = react.div({}, [
      react.fieldset({}, [
        react.label({'for': '${providerDiagnostics.provider.id}-controlled'}, [
          react.input(
              {'type': 'checkbox', 'onChange': _toggleControlledRequests}),
          react.span({}, 'Control Messages')
        ])
      ])
    ]);
    return CollapsiblePanel({
      'title': providerDiagnostics.provider.id,
      'header': controls
    }, [
      _renderOutgoingSection(),
      _renderPendingSection(),
      _renderIncomingStandardSection(),
      _renderIncomingRejectedSection(),
      _renderCompleteSection()
    ]);
  }

  _renderCompleteSection() {
    var rows = {' ': diagnostics.messageMap.complete};
    return MessageSection({
      'controllable': false,
      'onExpandMessage': onExpandMessage,
      'rows': rows,
      'title': 'Complete'
    });
  }

  _renderIncomingStandardSection() {
    var rows = {};
    providerDiagnostics.provider.interceptors.forEach((interceptor) {
      rows[interceptor.id] = diagnostics.messageMap.messagesAt(
          providerDiagnostics.provider, interceptor, 'incoming');
    });
    return MessageSection({
      'controllable': controllable,
      'onAdvanceMessage': diagnostics.advance,
      'onExpandMessage': onExpandMessage,
      'rows': rows,
      'title': 'Incoming'
    });
  }

  _renderIncomingRejectedSection() {
    var rows = {};
    providerDiagnostics.provider.interceptors.forEach((interceptor) {
      rows[interceptor.id] = diagnostics.messageMap.messagesAt(
          providerDiagnostics.provider, interceptor, 'incomingRejected');
    });
    return MessageSection({
      'controllable': controllable,
      'onAdvanceMessage': diagnostics.advance,
      'onExpandMessage': onExpandMessage,
      'rows': rows,
      'title': 'Incoming Rejected'
    });
  }

  _renderOutgoingSection() {
    var rows = {};
    providerDiagnostics.provider.interceptors.forEach((interceptor) {
      rows[interceptor.id] = diagnostics.messageMap.messagesAt(
          providerDiagnostics.provider, interceptor, 'outgoing');
    });
    return MessageSection({
      'controllable': controllable,
      'onAdvanceMessage': diagnostics.advance,
      'onExpandMessage': onExpandMessage,
      'rows': rows,
      'title': 'Outgoing'
    });
  }

  _renderPendingSection() {
    var rows = {' ': diagnostics.messageMap.pending};
    return MessageSection({
      'controllable': false,
      'onExpandMessage': onExpandMessage,
      'rows': rows,
      'title': 'Pending'
    });
  }

  _toggleControlledRequests(e) {
    bool controlled = e.target.checked;
    if (controlled) {
      diagnostics.controlFor(providerDiagnostics.provider);
    } else {
      diagnostics.releaseControlFor(providerDiagnostics.provider);
    }
    setState({'controllable': e.target.checked});
  }
}

var MessageSection = react.registerComponent(() => new _MessageSection());
class _MessageSection extends react.Component {
  bool get controllable => props['controllable'];
  Function get onAdvanceMessage => props['onAdvanceMessage'];
  Function get onExpandMessage => props['onExpandMessage'];
  Map<String, List<Context>> get rows => props['rows'];
  String get title => props['title'];

  getDefaultProps() => {
    'controllable': false,
    'onAdvanceMessage': (_) {},
    'onExpandMessage': (_) {},
    'rows': [],
    'title': ''
  };

  render() {
    var rowNodes = [];
    rows.forEach((row, messages) {
      rowNodes.add(react.div({}, [
        react.div({'className': 'wsdp-message-sub-section'}, row),
        react.div({
          'className': 'wsdp-message-sub-section-messages'
        }, messages.map((context) => Message({
          'context': context,
          'controllable': controllable,
          'onAdvance': onAdvanceMessage,
          'onExpand': onExpandMessage
        }))),
        react.div({'className': 'wsdp-clear'})
      ]));
    });

    return react.div({'className': 'wsdp-message-section'}, [
      react.div(
          {'className': 'wsdp-message-section-title'}, react.strong({}, title)),
      react.div({'className': 'wsdp-message-section-content'}, rowNodes)
    ]);
  }
}
