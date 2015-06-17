library w_service.src.diagnostic.components.styles;

String css = '''
.wsdp {
  box-sizing: border-box;
}


.wsdp-clear {
  width: 100%;
  height: 0;
  display: table;
  clear: both;
}


/* Diagnostic Panel */

.wsdp .wsdp-diagnostics {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  width: 100%;
  max-height: 600px;
  overflow-y: scroll;
  background-color: #888;
  color: #fff;
  font-family: 'Helvetica Neue', Helvetica, sans-serif;
}


/* Collapsible Panel */

.wsdp .wsdp-panel-header {
  height: 50px;
  line-height: 50px;
  padding: 0 10px;
  background-color: #666;
  border-bottom: 1px solid #444;
}

.wsdp .wsdp-panel-header:after {
  content: '';
  display: table;
  clear: both;
}

.wsdp .wsdp-panel-header-title {
  float: left;
  width: 180px;
  height: 50px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  text-decoration: none;
}

.wsdp .wsdp-panel-header-title, .wsdp .wsdp-panel-header-title:active {
  color: #fff;
}

.wsdp .wsdp-panel-header-title:before {
  content: ' \\25BC';
  display: inline-block;
  margin-right: 6px;
  font-size: 8px;
}

.wsdp .wsdp-panel-expanded > .wsdp-panel-header > .wsdp-panel-header-title:before {
  content: ' \\25B2';
}

.wsdp .wsdp-panel-header-content {
  margin-left: 200px;
}

.wsdp .wsdp-panel-header-content fieldset {
  margin: 0 20px;
}

.wsdp .wspd-panel-header-content label {
  margin: 0 5px;
}

.wsdp .wsdp-panel-header-content label > span {
  display: inline-block;
  margin: 0 5px;
}

.wsdp .wsdp-panel-content {
  display: none;
  padding-top: 10px;
}

.wsdp .wsdp-panel-expanded > .wsdp-panel-content {
  display: block;
}


/* Top bar */

.wsdp .wsdp-panel.main > .wsdp-panel-header {
  background-color: #444;
}

.wsdp .wsdp-panel.main > .wsdp-panel-content {
  padding-top: 0;
}


/* Overall Stats */

.wsdp .wsdp-stats {
  float: left;
  white-space: nowrap;
  overflow: hidden;
}


/* Message Ticker */

.wsdp .wsdp-message-ticker {
  position: relative;
  white-space: nowrap;
  overflow: hidden;
}

.wsdp .wsdp-message-ticker .fadeout {
  position: absolute;
  top: 0;
  left: 0;
  width: 80px;
  height: 50px;
  background-image: linear-gradient(to right, #444, #444 50%, rgba(0, 0, 0, 0));
}

.wsdp .wsdp-message-ticker > ul, .wsdp .wsdp-message-ticker > ul > li {
  margin: 0;
  padding: 0;
  list-style: none;
}

.wsdp .wsdp-message-ticker > ul {
  float: right;
  width: 5000px;
  white-space: normal;
}

.wsdp .wsdp-message-ticker > ul > li {
  float: right;
  margin-right: 10px;
}

.wsdp .wsdp-message-ticker .wsdp-message {
  margin: 13px 0;
  background-color: #888;
}


/* Detailed Message View */

.wsdp .wsdp-detailed-message-view {
  white-space: nowrap;
  overflow-x: scroll;
}

.wsdp .wsdp-detailed-message-view-empty {
  padding: 5px 10px;
  font-style: italic;
}

.wsdp .wsdp-detailed-message-view > ul, .wsdp .wsdp-detailed-message-view > ul > li {
  list-style: none;
  margin: 0;
  padding: 0;
}

.wsdp .wsdp-detailed-message-view > ul > li {
  display: inline-block;
}


/* Message */

.wsdp .wsdp-message {
  height: 24px;
  line-height: 24px;
  padding-left: 4px;
  background-color: #555;
}

.wsdp .wsdp-message-status, .wsdp .wsdp-message-method, .wsdp .wsdp-message-path {
  display: inline-block;
  margin-right: 4px;
}

.wsdp .wsdp-message-status-circle {
  float: left;
  width: 12px;
  height: 12px;
  margin: 6px 8px 6px 4px;
  border-radius: 6px;
  background-color: #fff;
}

.wsdp .wsdp-message-status-text {
  display: inline-block;
}

.wsdp .wsdp-message-advance, .wsdp .wsdp-message-close, .wsdp .wsdp-message-expand {
  float: right;
  width: 24px;
  margin-left: 5px;
  text-align: center;
  color: #555;
  background-color: #fff;
  text-decoration: none;
  font-weight: bold;
}

.wsdp .wsdp-message-advance {
  float: left;
  margin-left: -4px;
  margin-right: 4px;
}

.wsdp .wsdp-message-close {
  border-bottom: 1px solid #666;
}

.wsdp .wsdp-message-detailed {
  display: block;
  width: 300px;
  margin: 10px;
}

.wsdp .wsdp-message-detailed-title {
  width: 100%;
  height: 24px;
  line-height: 24px;
  padding-left: 4px;
  background-color: #666;
}

.wsdp .wsdp-message-detailed-content {
  width: 100%;
  padding: 4px;
  color: #111;
  background-color: #ddd;
  font-family: courier, monospace;
  overflow-x: scroll;
}

.wsdp .wsdp-message-detailed-content table, .wsdp .wsdp-message-detailed-content tbody, .wsdp .wsdp-message-detailed-content tr, .wsdp .wsdp-message-detailed-content td {
  border: none;
  margin: 0;
  padding: 0;
}

.wsdp .wsdp-message-detailed-content td {
  padding-bottom: 2px;
  vertical-align: top;
}

.wsdp .wsdp-message-detailed-content tr td:first-of-type {
  padding-right: 10px;
}


/* Message Section */

.wsdp .wsdp-message-section {
  margin-bottom: 10px;
}

.wsdp .wsdp-message-section-title {
  margin-bottom: 3px;
}

.wsdp .wsdp-message-section-content {
  margin-left: 40px;
}

.wsdp .wsdp-message-section .wsdp-message-sub-section {
  float: left;
  width: 160px;
  padding-right: 10px;
}

.wsdp .wsdp-message-section .wsdp-message-sub-section-messages {
  margin-left: 180px;
}

.wsdp .wsdp-message-section .wsdp-message {
  display: inline-block;
  margin: 0 10px 5px 0;
}


/* Skins */

.wsdp .wsdp-success {
  background-color: #66cc00;
}

.wsdp .wsdp-failure {
  background-color: #ee2724;
}

''';
