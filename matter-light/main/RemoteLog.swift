//
//  RemoteLog.swift
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

// Remote logging: poll a mock endpoint every 5s to see whether logging is
// currently enabled, and POST a JSON log message whenever the light's on/off
// state changes while enabled. Uses esp_http_client's C API directly rather
// than a C++ shim -- it's a plain C API, so it bridges into Swift cleanly.

/// Fixed-size buffer used to read HTTP response bodies; responses longer than
/// this are truncated.
private let responseBufferSize = 256

// Performs a synchronous GET and returns the response body (empty string on
// any failure -- a failed request should never crash the device).
func httpGet(url: String) -> String {
  var responseBody = ""

  url.withCString { cUrl in
    var config = esp_http_client_config_t()
    config.url = cUrl
    config.crt_bundle_attach = esp_crt_bundle_attach

    guard let client = esp_http_client_init(&config) else {
      print("httpGet: init failed")
      return
    }
    defer { esp_http_client_cleanup(client) }

    guard esp_http_client_set_method(client, HTTP_METHOD_GET) == ESP_OK else {
      print("httpGet: set_method failed")
      return
    }

    guard esp_http_client_open(client, 0) == ESP_OK else {
      print("httpGet: open failed")
      return
    }
    defer { esp_http_client_close(client) }

    guard esp_http_client_fetch_headers(client) >= 0 else {
      print("httpGet: fetch_headers failed")
      return
    }

    var buffer = [CChar](repeating: 0, count: responseBufferSize)
    let n = buffer.withUnsafeMutableBufferPointer { bufPtr in
      esp_http_client_read_response(client, bufPtr.baseAddress, Int32(bufPtr.count - 1))
    }
    if n > 0 {
      buffer[Int(n)] = 0
      responseBody = String(cString: buffer)
    }
  }

  return responseBody
}

// Performs a synchronous POST with a JSON body. Failures are logged, not fatal.
func httpPost(url: String, jsonBody: String) {
  url.withCString { cUrl in
    jsonBody.withCString { cBody in
      let bodyLen = Int32(jsonBody.utf8.count)

      var config = esp_http_client_config_t()
      config.url = cUrl
      config.crt_bundle_attach = esp_crt_bundle_attach

      guard let client = esp_http_client_init(&config) else {
        print("httpPost: init failed")
        return
      }
      defer { esp_http_client_cleanup(client) }

      guard esp_http_client_set_method(client, HTTP_METHOD_POST) == ESP_OK else {
        print("httpPost: set_method failed")
        return
      }
      guard esp_http_client_set_header(client, "Content-Type", "application/json") == ESP_OK else {
        print("httpPost: set_header failed")
        return
      }

      guard esp_http_client_open(client, bodyLen) == ESP_OK else {
        print("httpPost: open failed")
        return
      }
      defer { esp_http_client_close(client) }

      guard esp_http_client_write(client, cBody, bodyLen) == bodyLen else {
        print("httpPost: write failed")
        return
      }

      guard esp_http_client_fetch_headers(client) >= 0 else {
        print("httpPost: fetch_headers failed")
        return
      }

      var buffer = [CChar](repeating: 0, count: responseBufferSize)
      _ = buffer.withUnsafeMutableBufferPointer { bufPtr in
        esp_http_client_read_response(client, bufPtr.baseAddress, Int32(bufPtr.count - 1))
      }

      print("httpPost: status \(esp_http_client_get_status_code(client))")
    }
  }
}

/// Polls a remote endpoint for a logging-enabled flag and, while enabled,
/// POSTs a JSON log entry to a remote endpoint whenever the light's on/off
/// state changes. See the README's "Remote logging" section for the full
/// poll/log HTTP contract.
final class RemoteLogger {
  /// GET endpoint polled every 5s to check whether logging is enabled.
  let pollURL: String
  /// POST endpoint that state-change log entries (JSON body) are sent to.
  let logURL: String
  /// Last known logging-enabled state from `poll()`; gates whether
  /// `logStateChange(on:)` actually sends anything.
  var loggingEnabled: Bool = false

  /// - Parameters:
  ///   - pollURL: GET endpoint polled every 5s for the current logging-enabled state.
  ///   - logURL: POST endpoint that state-change log entries are sent to.
  init(pollURL: String, logURL: String) {
    self.pollURL = pollURL
    self.logURL = logURL
  }

  // Call every 5s. Determines whether logging is enabled from the GET
  // response's "enabled" JSON boolean field. If the field is missing, not a
  // boolean, or the response fails to parse as JSON, the previous value is
  // left unchanged.
  func poll() {
    let body = httpGet(url: pollURL)

    guard let root = body.withCString({ cJSON_Parse($0) }) else {
      print("RemoteLogger.poll: JSON parse failed")
      return
    }
    defer { cJSON_Delete(root) }

    guard let enabledItem = cJSON_GetObjectItemCaseSensitive(root, "enabled"),
      cJSON_IsBool(enabledItem) != 0
    else {
      print("RemoteLogger.poll: missing or non-boolean \"enabled\" field")
      return
    }

    loggingEnabled = cJSON_IsTrue(enabledItem) != 0
    print("RemoteLogger.poll: loggingEnabled=\(loggingEnabled)")
  }

  // Call whenever the light's on/off state actually changes.
  func logStateChange(on: Bool) {
    guard loggingEnabled else { return }
    let uptimeMs = Int(esp_timer_get_time() / 1000)
    let stateString = on ? "on" : "off"

    guard let root = cJSON_CreateObject() else {
      print("RemoteLogger.logStateChange: cJSON_CreateObject failed")
      return
    }
    defer { cJSON_Delete(root) }

    let addedState = stateString.withCString { cState in
      cJSON_AddStringToObject(root, "state", cState) != nil
    }
    guard addedState else {
      print("RemoteLogger.logStateChange: AddStringToObject failed")
      return
    }
    guard cJSON_AddNumberToObject(root, "uptime_ms", Double(uptimeMs)) != nil
    else {
      print("RemoteLogger.logStateChange: AddNumberToObject failed")
      return
    }

    guard let cJsonString = cJSON_PrintUnformatted(root) else {
      print("RemoteLogger.logStateChange: PrintUnformatted failed")
      return
    }
    defer { cJSON_free(cJsonString) }

    httpPost(url: logURL, jsonBody: String(cString: cJsonString))
  }
}
