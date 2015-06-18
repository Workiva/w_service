Examples
--------

> There is currently 1 example that demonstrates the usage of the `HttpProvider` with the help of the w_service diagnostic tool.

- [Sending and receiving messages with HttpProvider](http_provider)


### Building & Serving
You can run a shell script from the project root to build and serve the examples:
```
./tool/examples.sh
```

> This is the same as simply running `pub get && pub serve example --port 9000`.


### Server Component
Most of the examples will require a server to handle HTTP requests. You can run this server by running a shell script from the project root:
```
./tool/server.sh
```

> This is the same as running `dart --checked tool/server/server.dart`.


### Viewing (Compiled JS)
Open [http://localhost:9000](http://localhost:9000) in your browser of choice.

### Viewing (Dartium)
```
dartium --checked http://localhost:9000
```