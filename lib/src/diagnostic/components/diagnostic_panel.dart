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

library w_service.src.diagnostic.components.diagnostic_panel;

import 'dart:async';

import 'package:react/react.dart' as react;
import 'package:w_service/w_service.dart';

import 'package:w_service/src/diagnostic/components/collapsible_panel.dart'
    show CollapsiblePanel;
import 'package:w_service/src/diagnostic/components/detailed_message_view.dart'
    show DetailedMessageView;
import 'package:w_service/src/diagnostic/components/message_stats.dart'
    show MessageStats;
import 'package:w_service/src/diagnostic/components/message_ticker.dart'
    show MessageTicker;
import 'package:w_service/src/diagnostic/components/provider_panel.dart'
    show ProviderPanel;
import 'package:w_service/src/diagnostic/components/styles.dart' show css;
import 'package:w_service/src/diagnostic/diagnostics.dart' show Diagnostics;
import 'package:w_service/src/diagnostic/provider_diagnostics.dart'
    show ProviderDiagnostics;

const int _maxTickerMessages = 10;

var DiagnosticPanel = react.registerComponent(() => new _DiagnosticPanel());
class _DiagnosticPanel extends react.Component {
  Diagnostics get diagnostics => props['diagnostics'];

  List<Context> get detailedMessages => state['detailedMessages'];
  List<Context> get messages => state['messages'];
  List<ProviderDiagnostics> get providerDiagnostics =>
      state['providerDiagnostics'];

  List<StreamSubscription> _subscriptions = [];

  getDefaultProps() => {'diagnostics': null};

  getInitialState() =>
      {'detailedMessages': [], 'messages': [], 'providerDiagnostics': []};

  componentDidMount(rootNode) {
    _subscribeToDiagnostics();
  }

  componentWillUnmount() {
    _unsubscribeFromDiagnostics();
  }

  render() {
    var header = react.div({}, [
      MessageStats({
        'http': diagnostics.httpStats,
        'webSocket': diagnostics.webSocketStats
      }),
      MessageTicker({
        'messages': diagnostics.messageMap.recent,
        'onExpandMessage': diagnostics.messageMap.viewDetailsFor
      })
    ]);

    var body = [];
    body.add(DetailedMessageView({
      'messages': diagnostics.messageMap.detailed,
      'onCloseMessage': diagnostics.messageMap.closeDetailsFor
    }));
    providerDiagnostics.forEach((providerDiagnostics) {
      body.add(ProviderPanel({
        'diagnostics': diagnostics,
        'providerDiagnostics': providerDiagnostics,
        'onExpandMessage': diagnostics.messageMap.viewDetailsFor
      }));
    });

    return react.div({'className': 'wsdp'}, [
      react.style({'dangerouslySetInnerHTML': {'__html': css}}),
      react.div({'className': 'wsdp-diagnostics'}, CollapsiblePanel({
        'className': 'main',
        'title': 'w_service diagnostics',
        'header': header
      }, body))
    ]);
  }

  void _subscribeToDiagnostics() {
    _subscriptions.add(diagnostics.messageMap.stream.listen((messageMap) {
      setState({'messageMap': messageMap});
    }));
    _subscriptions.add(diagnostics.providerDiagnosticsStream
        .listen((providerDiagnostics) {
      setState({'providerDiagnostics': providerDiagnostics});
    }));
  }

  void _unsubscribeFromDiagnostics() {
    _subscriptions.forEach((subscription) {
      subscription.cancel();
    });
    _subscriptions = [];
  }
}
