/// Configure w_service for the server.
library w_service.w_service_server;

import 'package:w_transport/w_transport_server.dart'
    show configureWTransportForServer;

/// Configure w_service for use on the server.
///
/// Must be called before using any of the w_service classes.
///
///     import 'package:w_service/w_service_server.dart'
///         show configureWServiceForServer;
///
///     void main() {
///       configureWServiceForServer();
///     }
void configureWServiceForServer() {
  configureWTransportForServer();
}
