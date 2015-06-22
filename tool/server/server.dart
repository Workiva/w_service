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

library w_service.tool.server.server;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

int _csrfCount = 0;

String generateCsrfToken() {
  return 'csrf-token-${_csrfCount++}';
}

void handleRequest(HttpRequest request) {
  request.response.headers.set('Access-Control-Allow-Origin', '*');
  request.response.headers.set('Access-Control-Allow-Methods', [
    'DELETE',
    'GET',
    'HEAD',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
  ].join(','));
  if (request.headers.value('Access-Control-Request-Headers') != null) {
    request.response.headers.set('Access-Control-Allow-Headers', request.headers.value('Access-Control-Request-Headers'));
  }
  request.response.headers.set('Access-Control-Expose-Headers', 'x-xsrf-token');

  String csrf = request.headers.value('x-xsrf-token');
  int havok = request.headers.value('x-havok') != null
      ? int.parse(request.headers.value('x-havok'))
      : 0;

  request.response.headers.set('x-xsrf-token', generateCsrfToken());

  // Potentially produce an error, based on given havok percentage
  if (shouldError(havok)) {
    // Produce a random error
    produceError(request);
  } else {
    // Return a 200 OK
    request.response.statusCode = HttpStatus.OK;
    request.response.write(JSON.encode({'result': 'success'}));
    request.response.close();
  }

  print('[${new DateTime.now().toString()}] ${request.method}\t${request.response.statusCode}\t${request.uri.toString()}');
}

void produceError(HttpRequest request) {
  switch (new Random().nextInt(6)) {
    case 0: // 400
      request.response.statusCode = HttpStatus.BAD_REQUEST;
      break;
    case 1: // 403
      request.response.statusCode = HttpStatus.FORBIDDEN;
      break;
    case 2: // 404
      request.response.statusCode = HttpStatus.NOT_FOUND;
      break;
    case 3: // 500
      request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
      break;
    case 4: // 502
      request.response.statusCode = HttpStatus.BAD_GATEWAY;
      break;
    case 5: // request timeout
      return;
  }
  request.response.close();
}

bool shouldError(int havok) {
  return new Random().nextInt(100) + 1 <= havok;
}

main() async {
  HttpServer server = await HttpServer.bind('localhost', 8024);
  server.listen(handleRequest);
  print('Server ready - listening on http://localhost:8024');
}