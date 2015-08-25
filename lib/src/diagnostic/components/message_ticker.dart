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
    return react.div({
      'className': 'wsdp-message-ticker'
    }, [
      react.div({'className': 'fadeout'}),
      react.ul({}, msgs)
    ]);
  }
}
