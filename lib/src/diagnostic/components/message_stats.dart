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

library w_service.src.diagnostic.components.message_stats;

import 'package:react/react.dart' as react;

import 'package:w_service/src/diagnostic/diagnostic_stats.dart'
    show HttpStats, WebSocketStats;

var MessageStats = react.registerComponent(() => new _MessageStats());
class _MessageStats extends react.Component {
  HttpStats get http => props['http'];
  WebSocketStats get webSocket => props['webSocket'];

  getDefaultProps() =>
      {'http': new HttpStats(), 'webSocket': new WebSocketStats()};

  render() {
    var stats = [];
    if (http.total > 0) {
      var httpStats = [];
      httpStats.add(react.span({'className': 'wsdp-stats-title'}, 'HTTP: '));
      httpStats.add(react.span({
        'className': 'wsdp-stats-rate'
      }, '${http.successRate.toStringAsFixed(2)}%'));
      httpStats.add(react.span({
        'className': 'wsdp-stats-ratio'
      }, ' (${http.successes}/${http.total})'));
      if (http.retries > 0) {
        httpStats.add(react.span(
            {'className': 'wsdp-stats-retries'}, ' ${http.retries} retries'));
      }
      stats.add(react.div({'className': 'wsdp-stats'}, httpStats));
    }

    if (webSocket.total > 0) {
      var webSocketStats = [];
      webSocketStats
          .add(react.span({'className': 'wsdp-stats-title'}, 'WebSocket: '));
      webSocketStats.add(react.span({
        'className': 'wsdp-stats-rate'
      }, '${webSocket.successRate.toStringAsFixed(2)}%'));
      webSocketStats.add(react.span({
        'className': 'wsdp-stats-ratio'
      }, ' (${webSocket.successes}/${webSocket.total})'));
      stats.add(react.div({'className': 'wsdp-stats'}, webSocketStats));
    }

    return react.div({}, stats);
  }
}
