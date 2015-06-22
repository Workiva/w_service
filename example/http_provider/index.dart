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

library w_service.example.http_provider.index;

import 'dart:async';
import 'dart:html';
import 'dart:math' show Random;

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as react_client;
import 'package:w_service/w_service.dart';
import 'package:w_service/w_service_client.dart'
    show configureWServiceForBrowser;
import 'package:w_service/w_service_diagnostic.dart' deferred as diagnostics;

// TODO: Send data on every request and monitor the # of bytes transferred

var appComponent = react.registerComponent(() => new AppComponent());
class AppComponent extends react.Component {
  Map getDefaultProps() {
    return {
      'disableDiagnostics': () {},
      'enableDiagnostics': () {},
      'sendRequest': () {},
      'setHavokPercentage': (_) {},
      'setRequestsPerSecond': (_) {},
      'startRequestStream': () {},
      'stopRequestStream': () {},
    };
  }

  render() {
    return react.div({'className': 'container-wide'}, [
      react.h1(
          {}, [react.span({}, 'Example: '), react.code({}, 'HttpProvider'),]),
      react.div({'className': 'row'}, [
        react.div({'className': 'col-md-12'}, controlComponent({
          'disableDiagnostics': props['disableDiagnostics'],
          'enableDiagnostics': props['enableDiagnostics'],
          'sendRequest': props['sendRequest'],
          'setHavokPercentage': props['setHavokPercentage'],
          'setRequestsPerSecond': props['setRequestsPerSecond'],
          'startRequestStream': props['startRequestStream'],
          'stopRequestStream': props['stopRequestStream'],
        })),
      ])
    ]);
  }
}

var controlComponent = react.registerComponent(() => new ControlComponent());
class ControlComponent extends react.Component {
  Map getInitialState() {
    return {'diagnosticsEnabled': false, 'streaming': false};
  }

  Map getDefaultProps() {
    return {
      'disableDiagnostics': () {},
      'enableDiagnostics': () {},
      'sendRequest': () {},
      'setHavokPercentage': (_) {},
      'setRequestsPerSecond': (_) {},
      'startRequestStream': () {},
      'stopRequestStream': () {},
    };
  }

  render() {
    var diagnosticsButton;
    if (state['diagnosticsEnabled']) {
      diagnosticsButton = react.button({
        'className': 'btn btn-danger',
        'onClick': _disableDiagnostics
      }, 'Disable Diagnostics');
    } else {
      diagnosticsButton = react.button({
        'className': 'btn btn-success',
        'onClick': _enableDiagnostics
      }, 'Enable Diagnostics');
    }

    var requestStreamButton;
    if (state['streaming']) {
      requestStreamButton = react.button({
        'className': 'btn btn-danger',
        'onClick': _stopRequestStream
      }, 'Stop Request Stream');
    } else {
      requestStreamButton = react.button({
        'className': 'btn btn-success',
        'onClick': _startRequestStream
      }, 'Start Request Stream');
    }

    return react.div({'className': 'controls'}, react.form({
      'className': 'form-inline'
    }, react.fieldset({}, [
      react.div({'className': 'form-group'}, diagnosticsButton),
      react.div({'className': 'form-group'}, react.button({
        'className': 'btn btn-default',
        'onClick': _sendRequest
      }, 'Single Request')),
      react.div({'className': 'form-group'}, requestStreamButton),
      react.div({'className': 'form-group'}, [
        react.label({'htmlFor': 'rps'}, 'RPS'),
        react.input({
          'className': 'form-control',
          'id': 'rps',
          'onChange': _setRequestsPerSecond,
          'placeholder': 'requests per second'
        }),
      ]),
      react.div({'className': 'form-group'}, [
        react.label({'htmlFor': 'havok'}, 'Havok'),
        react.input({
          'className': 'form-control',
          'id': 'havok',
          'onChange': _setHavokPercentage,
          'placeholder': '% of requests to error (0-100)'
        }),
      ]),
    ])));
  }

  _disableDiagnostics(e) {
    e.preventDefault();
    setState({'diagnosticsEnabled': false});
    props['disableDiagnostics']();
  }

  _enableDiagnostics(e) {
    e.preventDefault();
    setState({'diagnosticsEnabled': true});
    props['enableDiagnostics']();
  }

  _sendRequest(e) {
    e.preventDefault();
    props['sendRequest']();
  }

  _setHavokPercentage(e) {
    try {
      int v = !e.target.value.isEmpty ? int.parse(e.target.value) : 0;
      props['setHavokPercentage'](v);
    } catch (e) {}
  }

  _setRequestsPerSecond(e) {
    try {
      int v = !e.target.value.isEmpty ? double.parse(e.target.value) : 1;
      props['setRequestsPerSecond'](v);
    } catch (e) {}
  }

  _startRequestStream(e) {
    e.preventDefault();
    setState({'streaming': true});
    props['startRequestStream']();
  }

  _stopRequestStream(e) {
    e.preventDefault();
    setState({'streaming': false});
    props['stopRequestStream']();
  }
}

void main() {
  react_client.setClientConfiguration();
  configureWServiceForBrowser();

  HttpProvider http = new HttpProvider(id: 'example-http-provider')
    ..uri = Uri.parse('http://localhost:8024')
    ..use(new CsrfInterceptor())
    ..use(new JsonInterceptor())
    ..use(new TimeoutInterceptor(maxRequestDuration: new Duration(seconds: 4)));

  Duration rpsDuration = new Duration(seconds: 1);
  Timer requestStream;

  void disableDiagnostics() {
    diagnostics.unwatch(http);
    diagnostics.disableDiagnostics();
  }

  enableDiagnostics() async {
    await diagnostics.loadLibrary();
    diagnostics.enableDiagnostics();
    diagnostics.watch(http);
  }

  sendRequest() async {
    http.data = {'payload': 'data'};
    switch (new Random().nextInt(4)) {
      case 0:
        http.path = 'api/session';
        break;
      case 1:
        http.path = 'api/status';
        break;
      case 2:
        http.path = 'api/tasks/';
        break;
      case 3:
        http.path = '';
        break;
    }
    try {
      switch (new Random().nextInt(7)) {
        case 0:
          await http.delete();
          break;
        case 1:
          await http.get();
          break;
        case 2:
          await http.head();
          break;
        case 3:
          await http.options();
          break;
        case 4:
          await http.patch();
          break;
        case 5:
          await http.post();
          break;
        case 6:
          await http.put();
          break;
      }
    } catch (e) {
      print(e);
    }
  }

  void setHavokPercentage(int havok) {
    http.headers['x-havok'] = havok.toString();
  }

  void setRequestsPerSecond(double rps) {
    rpsDuration = new Duration(milliseconds: (1 / rps * 1000).round());
  }

  void startRequestStream() {
    requestStream = new Timer.periodic(rpsDuration, (_) {
      sendRequest();
    });
  }

  void stopRequestStream() {
    requestStream.cancel();
  }

  react.render(appComponent({
    'disableDiagnostics': disableDiagnostics,
    'enableDiagnostics': enableDiagnostics,
    'sendRequest': sendRequest,
    'setHavokPercentage': setHavokPercentage,
    'setRequestsPerSecond': setRequestsPerSecond,
    'startRequestStream': startRequestStream,
    'stopRequestStream': stopRequestStream,
  }), querySelector('#app'));

  HttpRequest.request('http://localhost:8024', method: 'GET');
}
