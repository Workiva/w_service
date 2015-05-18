library w_service.test.mocks.w_http;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:w_transport/w_http.dart';

class MockWHttp implements WHttp {
  MockWHttp({bool autoFlush: true}) : super() {
    this.autoFlush = autoFlush;
    _requests = _requestStreamController.stream.asBroadcastStream();
  }

  bool autoFlush;

  StreamController<MockWRequest> _requestStreamController =
      new StreamController<MockWRequest>();
  Stream<MockWRequest> get requests => _requests;
  Stream<MockWRequest> _requests;
  WRequest newRequest() {
    MockWRequest req =
        spy(new MockWRequest(), new ControlledWRequest(autoFlush: autoFlush));
    _requestStreamController.add(req);
    return req;
  }
  void close() {
    _requestStreamController.close();
  }
}

class MockWRequest extends Mock implements ControlledWRequest {}

class ControlledWRequest extends Mock implements WRequest {
  ControlledWRequest({bool autoFlush: true}) : this.autoFlush = autoFlush;

  bool autoFlush;

  Completer _ready = new Completer();

  Future _mockDispatch() {
    _ready.complete();
    if (autoFlush) {
      complete();
    }
    return _completer.future;
  }

  Completer<WResponse> _completer = new Completer<WResponse>();

  void complete([WResponse response]) {
    _ready.future.then((_) {
      _completer.complete(response != null ? response : new MockWResponse());
    });
  }

  void completeError(Object error) {
    _ready.future.then((_) {
      _completer.completeError(error);
    });
  }

  Future delete([Uri uri]) => _mockDispatch();
  Future get([Uri uri]) => _mockDispatch();
  Future head([Uri uri]) => _mockDispatch();
  Future options([Uri uri]) => _mockDispatch();
  Future patch([Uri uri, data]) => _mockDispatch();
  Future post([Uri uri, data]) => _mockDispatch();
  Future put([Uri uri, data]) => _mockDispatch();
  Future trace([Uri uri]) => _mockDispatch();
}

class MockWResponse extends Mock implements WResponse {}
