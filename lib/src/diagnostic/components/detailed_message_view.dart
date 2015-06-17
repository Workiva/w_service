library w_service.src.diagnostic.components.detailed_message_view;

import 'package:react/react.dart' as react;

import 'package:w_service/src/diagnostic/components/collapsible_panel.dart'
    show CollapsiblePanel;
import 'package:w_service/src/diagnostic/components/message.dart' show Message;
import 'package:w_service/w_service.dart';

var DetailedMessageView =
    react.registerComponent(() => new _DetailedMessageView());
class _DetailedMessageView extends react.Component {
  List<Context> get messages => props['messages'];
  Function get onCloseMessage => props['onCloseMessage'];

  getDefaultProps() => {'messages': [], 'onCloseMessage': (_) {}};

  render() {
    var body;
    if (messages.length > 0) {
      var messageList = [];
      messages.forEach((context) {
        messageList.add(react.li({}, Message({
          'context': context,
          'detailed': true,
          'onClose': onCloseMessage
        })));
      });
      body = react.ul({}, messageList);
    } else {
      body = react.p({
        'className': 'wsdp-detailed-message-view-empty'
      }, 'No messages. Click "+" on a message to view it here.');
    }

    return CollapsiblePanel({'title': 'Messages'}, react.div({
      'className': 'wsdp-detailed-message-view'
    }, [body, react.div({'className': 'wsdp-clear'})]));
  }
}
