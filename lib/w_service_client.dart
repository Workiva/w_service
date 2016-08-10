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

/// Configure w_service for the browser.
@Deprecated(
    'Use the w_transport package instead - https://github.com/Workiva/w_transport')
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
