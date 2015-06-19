library w_service.src.diagnostic.components.message;

import 'package:react/react.dart' as react;
import 'package:w_service/w_service.dart';

var Message = react.registerComponent(() => new _Message());
class _Message extends react.Component {
  Context get context => props['context'];
  bool get controllable => props['controllable'];
  bool get detailed => props['detailed'];

  /// HTTP-specific details
  /// These should only be used when dealing with an HttpContext instance.

  HttpContext get httpContext => context as HttpContext;
  String get httpMethod => httpContext.request.method != null
      ? httpContext.request.method
      : httpContext.meta['method'];
  String get httpPath {
    var path = httpContext.request.uri.path;
    return path != null && path != '' ? path : '/';
  }
  String get httpResponseData => state['httpResponseData'];
  Function get onAdvance => props['onAdvance'];
  Function get onClose => props['onClose'];
  Function get onExpand => props['onExpand'];

  getDefaultProps() => {
    'context': null,
    'controllable': false,
    'detailed': false,
    'onAdvance': (_) {},
    'onClose': (_) {},
    'onExpand': (_) {}
  };

  getInitialState() => {'httpResponseData': null};

  render() {
    if (context == null) return react.div({});
    if (context is HttpContext) {
      return detailed ? _renderDetailedHttpMessage() : _renderHttpMessage();
    }
  }

  _advanceMessage(e) {
    e.preventDefault();
    onAdvance(context);
  }

  _closeMessage(e) {
    e.preventDefault();
    onClose(context);
  }

  _expandMessage(e) {
    e.preventDefault();
    onExpand(context);
  }

  _loadResponseData(e) {
    e.preventDefault();
    httpContext.response.asText().then((text) {
      setState({'httpResponseData': text});
    });
  }

  _renderHttpStatus() {
    var statusClass = 'wsdp-message-status-circle';
    var statusText = '...';
    if (httpContext.response != null) {
      statusText = httpContext.response.status.toString();
      if (httpContext.response.status >= 200 &&
          httpContext.response.status < 300) {
        statusClass += ' wsdp-success';
      } else {
        statusClass += ' wsdp-failure';
      }
    } else if (httpContext.meta['canceled'] == true) {
      statusClass += ' wsdp-failure';
      statusText = '(canceled)';
    }
    return react.div({'className': 'wsdp-message-status'}, [
      react.div({'className': statusClass}),
      react.div({'className': 'wsdp-message-status-text'}, statusText)
    ]);
  }

  _renderHttpMessage() {
    var title = [];
    if (controllable) {
      title.add(react.a({
        'className': 'wsdp-message-advance',
        'onClick': _advanceMessage,
        'dangerouslySetInnerHTML': {'__html': '&rarr;'}
      }));
    }
    title.addAll([
      _renderHttpStatus(),
      react.div({'className': 'wsdp-message-method'}, httpMethod),
      react.div({'className': 'wsdp-message-path'}, httpPath),
      react.a(
          {'className': 'wsdp-message-expand', 'onClick': _expandMessage}, '+')
    ]);
    return react.div({'className': 'wsdp-message'}, title);
  }

  _renderDetailedHttpMessage() {
    var providerId = httpContext.meta['providerId'];
    var uri = httpContext.request.uri.toString();

    var requestHeaders = httpContext.request.headers.toString();
    var requestBody = httpContext.request.data != null
        ? httpContext.request.data.toString()
        : '';

    var responseHeaders = httpContext.response != null
        ? httpContext.response.headers.toString()
        : '';
    var responseBody = httpResponseData != null
        ? [react.a({'onClick': _loadResponseData}, 'reload'), httpResponseData]
        : react.a({'onClick': _loadResponseData}, 'load');

    var error = httpContext.meta['error'] != null
        ? httpContext.meta['error'].toString()
        : '';

    var title = [
      _renderHttpStatus(),
      react.div({'className': 'wsdp-message-method'}, httpMethod),
      react.div({'className': 'wsdp-message-path'}, httpPath),
      react.a({
        'className': 'wsdp-message-close',
        'onClick': _closeMessage,
        'dangerouslySetInnerHTML': {'__html': '&times;'}
      })
    ];

    return react.div({'className': 'wsdp-message-detailed'}, [
      react.div({'className': 'wsdp-message-detailed-title'}, title),
      react.div({
        'className': 'wsdp-message-detailed-content'
      }, react.table({}, react.tbody({}, [
        react.tr({}, [react.td({}, 'provider:'), react.td({}, providerId)]),
        react.tr({}, [react.td({}, 'uri:'), react.td({}, uri)]),
        react.tr({}, react.td({}, react.strong({}, 'request'))),
        react.tr({}, [react.td({}, 'headers:'), react.td({}, requestHeaders)]),
        react.tr({}, [react.td({}, 'body:'), react.td({}, requestBody)]),
        react.tr({}, react.td({}, react.strong({}, 'response'))),
        react.tr({}, [react.td({}, 'headers:'), react.td({}, responseHeaders)]),
        react.tr({}, [react.td({}, 'body:'), react.td({}, responseBody)]),
        react.tr({}, [react.td({}, 'error:'), react.td({}, error)])
      ])))
    ]);
  }
}
