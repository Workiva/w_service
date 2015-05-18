library w_service.test.mocks.w_http;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:w_transport/w_http.dart';

class MockWHttp implements WHttp {
  StreamController<MockWRequest> _requestStreamController =
      new StreamController<MockWRequest>();
  Stream<MockWRequest> get requests => _requestStreamController.stream;
  WRequest newRequest() {
    MockWRequest req = new MockWRequest();
    _requestStreamController.add(req);
    return req;
  }
  void close() {
    _requestStreamController.close();
  }
}

class MockWRequest extends Mock implements WRequest {}
