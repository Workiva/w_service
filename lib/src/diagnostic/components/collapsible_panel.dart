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

library w_service.src.diagnostic.components.collapsible_panel;

import 'package:react/react.dart' as react;

var CollapsiblePanel = react.registerComponent(() => new _CollapsiblePanel());
class _CollapsiblePanel extends react.Component {
  get children => props['children'];
  get expanded => state['expanded'];
  get header => props['header'];
  String get className => props['className'];
  get title => props['title'];

  getDefaultProps() => {'header': '', 'className': '', 'title': ''};

  getInitialState() => {'expanded': false};

  render() {
    var panelClassStr = 'wsdp-panel';
    if (expanded) {
      panelClassStr += ' wsdp-panel-expanded';
    }
    if (className != null) {
      panelClassStr += ' $className';
    }
    return react.div({'className': panelClassStr}, [
      react.div({'className': 'wsdp-panel-header'}, [
        react.a({
          'className': 'wsdp-panel-header-title',
          'onClick': _togglePanel
        }, react.strong({}, title)),
        react.div({'className': 'wsdp-panel-header-content'}, header)
      ]),
      react.div({'className': 'wsdp-panel-content'}, [
        react.div({'className': 'wsdp-clear'}),
        react.div({}, children)
      ])
    ]);
  }

  void _togglePanel(e) {
    e.preventDefault();
    setState({'expanded': !expanded});
  }
}
