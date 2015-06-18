/// Configure w_service for the browser.
library w_service.w_service_client;

import 'package:w_transport/w_transport_client.dart'
    show configureWTransportForBrowser;

/// Configure w_service for use in the browser.
///
/// Must be called before using any of the w_service classes.
///
///     import 'package:w_service/w_service_client.dart'
///         show configureWServiceForBrowser;
///
///     void main() {
///       configureWServiceForBrowser();
///     }
void configureWServiceForBrowser() {
  configureWTransportForBrowser();
}
