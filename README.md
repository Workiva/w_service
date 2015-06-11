w_service (Dart)
================

> Platform agnostic library for sending and receiving data messages between an application and a server with the ability to shape traffic and transform data through the use of message interceptors.


## What?

The `w_service` package provides a data transport layer that makes message preparation, data transformation, and traffic shaping easy.

`w_service` does **not** directly interact with data transport protocols like HTTP and WebSocket. It utilizes [`w_transport`](https://github.com/Workiva/w_transport) - a platform-agnostic library with ready to use transport classes for sending and receiving data.

<br>


## Why?

Creating a service API often starts out with a simple interface between client and server with some basic error handling. But, as an application grows, the demand for a higher quality service tier inevitably arises. The wish list usually includes more sophisticated fault tolerance, retry logic, data transforms, and traffic shaping.

`w_service`'s goal is to provide you with classes and patterns designed with these ideas in mind so you can scale your service tier to handle comprehensive use cases while eliminating unnecessary complexity.

<br>


## How?

`w_service` includes ready to use classes for immediate consumption and is built with extensibility and composability in mind for more customized applications. It makes data transformation and traffic shaping easy by leveraging the interceptor pattern to compose independent pieces of logic into a single workflow for every single service message.

This is accomplished through the use of **Providers**, **Interceptors**, and an **InterceptorManager**.

For more detailed information on these concepts, check out the [w_service wiki](https://github.com/Workiva/w_service/wiki).