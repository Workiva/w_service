library w_service.src.diagnostic.components.message_stats;

import 'package:react/react.dart' as react;

import 'package:w_service/src/diagnostic/diagnostic_stats.dart' show HttpStats, WebSocketStats;

var MessageStats = react.registerComponent(() => new _MessageStats());
class _MessageStats extends react.Component {
  HttpStats get http => props['http'];
  WebSocketStats get webSocket => props['webSocket'];

  getDefaultProps() => {'http': new HttpStats(), 'webSocket': new WebSocketStats()};

  render() {
    var stats = [];
    if (http.total > 0) {
      var httpStats = [];
      httpStats.add(react.span({'className': 'wsdp-stats-title'}, 'HTTP: '));
      httpStats.add(react.span({'className': 'wsdp-stats-rate'}, '${http.successRate.toStringAsFixed(2)}%'));
      httpStats.add(react.span({'className': 'wsdp-stats-ratio'}, ' (${http.successes}/${http.total})'));
      if (http.retries > 0) {
        httpStats.add(react.span({'className': 'wsdp-stats-retries'}, ' ${http.retries} retries'));
      }
      stats.add(react.div({'className': 'wsdp-stats'}, httpStats));
    }

    if (webSocket.total > 0) {
      var webSocketStats = [];
      webSocketStats.add(react.span({'className': 'wsdp-stats-title'}, 'WebSocket: '));
      webSocketStats.add(react.span({'className': 'wsdp-stats-rate'}, '${webSocket.successRate.toStringAsFixed(2)}%'));
      webSocketStats.add(react.span({'className': 'wsdp-stats-ratio'}, ' (${webSocket.successes}/${webSocket.total})'));
      stats.add(react.div({'className': 'wsdp-stats'}, webSocketStats));
    }

    return react.div({}, stats);
  }
}