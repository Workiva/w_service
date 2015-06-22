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

library w_service.test.mocks.w_http;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:w_transport/w_transport.dart';

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

class MockWRequest extends Mock implements ControlledWRequest {
  // this tells Dart analyzer you meant not to implement all methods,
  // and not to hint/warn that methods are missing
  noSuchMethod(i) => super.noSuchMethod(i);
}

class ControlledWRequest extends Mock implements WRequest {
  bool autoFlush;
  Map headers = {};
  Completer<WResponse> _completer = new Completer<WResponse>();
  Completer _ready = new Completer();

  ControlledWRequest({bool autoFlush: true}) : this.autoFlush = autoFlush;

  Future _mockDispatch() {
    _ready.complete();
    if (autoFlush) {
      complete();
    }
    return _completer.future;
  }

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

  // this tells Dart analyzer you meant not to implement all methods,
  // and not to hint/warn that methods are missing
  noSuchMethod(i) => super.noSuchMethod(i);
}

class MockWResponse extends Mock implements WResponse {
  // this tells Dart analyzer you meant not to implement all methods,
  // and not to hint/warn that methods are missing
  noSuchMethod(i) => super.noSuchMethod(i);
}
