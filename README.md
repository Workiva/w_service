# w_service
[![Pub](https://img.shields.io/pub/v/w_service.svg)](https://pub.dartlang.org/packages/w_service) [![Build Status](https://travis-ci.org/Workiva/w_service.svg?branch=master)](https://travis-ci.org/Workiva/w_service) [![codecov.io](http://codecov.io/github/Workiva/w_service/coverage.svg?branch=master)](http://codecov.io/github/Workiva/w_service?branch=master)

> Platform agnostic library for sending and receiving data messages between an application and a server with the ability to shape traffic and transform data through the use of message interceptors.


## What?

The `w_service` package provides a data transport layer that makes message preparation, data transformation, and traffic shaping easy.

`w_service` does **not** directly interact with data transport protocols like HTTP and WebSocket. It utilizes [`w_transport`](https://github.com/Workiva/w_transport) - a platform-agnostic library with ready to use transport classes for sending and receiving data.



## Why?

Creating a service API often starts out with a simple interface between client and server with some basic error handling. But, as an application grows, the demand for a higher quality service tier inevitably arises. The wish list usually includes more sophisticated fault tolerance, retry logic, data transforms, and traffic shaping.

`w_service`'s goal is to provide you with classes and patterns designed with these ideas in mind so you can scale your service tier to handle comprehensive use cases while eliminating unnecessary complexity.



## How?

`w_service` includes ready to use classes for immediate consumption and is built with extensibility and composability in mind for more customized applications. It makes data transformation and traffic shaping easy by leveraging the interceptor pattern to compose independent pieces of logic into a single workflow for every single service message.

This is accomplished through the use of **Providers**, **Interceptors**, and an **InterceptorManager**.

For more detailed information on these concepts, check out the [w_service wiki](https://github.com/Workiva/w_service/wiki).



## Platform Agnostic
The main library (`w_service/w_service.dart`) is built on [w_transport](https://github.com/Workiva/w_transport) (also platform-agnostic) and depends on neither `dart:html` nor `dart:io`, making it platform agnostic. This means you can use the `w_service` library to build components, libraries, or APIs that will be reusable in the browser AND on the server.

The end consumer will make the decision between client and server, most likely in a main() block.

## Usage in the Browser
```dart
import 'package:w_service/w_service_client.dart' show configureWServiceForBrowser;

void main() {
  configureWServiceForBrowser();
}
```

## Usage on the Server
```dart
import 'package:w_service/w_service_server.dart' show configureWServiceForServer;

void main() {
  configureWServiceForServer();
}
```

## Development

This project leverages [the dart_dev package](https://github.com/Workiva/dart_dev)
for most of its tooling needs, including static analysis, code formatting,
running tests, collecting coverage, and serving examples. Check out the dart_dev
readme for more information.