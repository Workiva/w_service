library w_service.src.diagnostic.components.message_ticker;

import 'package:react/react.dart' as react;
import 'package:w_service/w_service.dart';

import 'package:w_service/src/diagnostic/components/message.dart' show Message;

var MessageTicker = react.registerComponent(() => new _MessageTicker());
class _MessageTicker extends react.Component {
  List<Context> get messages => props['messages'];
  Function get onExpandMessage => props['onExpandMessage'];

  getDefaultProps() => {'messages': [], 'onExpandMessage': (_) {}};

  render() {
    var msgs = messages.map((message) {
      return react.li(
          {}, Message({'context': message, 'onExpand': onExpandMessage}));
    });
    return react.div({'className': 'wsdp-message-ticker'}, [
      react.div({'className': 'fadeout'}),
      react.ul({}, msgs)
    ]);
  }
}
