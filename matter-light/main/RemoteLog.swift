// Remote logging: poll a mock endpoint every 5s to see whether logging is
// currently enabled, and POST a JSON log message whenever the light's on/off
// state changes while enabled. Uses esp_http_client's C API directly rather
// than a C++ shim -- it's a plain C API, so it bridges into Swift cleanly.

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

// ASCII case-insensitive substring search, done at the byte level: Embedded
// Swift's stdlib doesn't link in String.contains(_:) for substring search
// (only the single-Character overload) or String.lowercased() (Unicode
// case-folding tables aren't linked into this freestanding build), same
// reason hello-world/main/Main.swift operates on .utf8 bytes instead of
// Characters.
private func asciiToLower(_ byte: UInt8) -> UInt8 {
  (byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "Z")) ? byte + 32 : byte
}

private func containsCaseInsensitive(_ haystack: String, _ needle: String) -> Bool {
  let h = Array(haystack.utf8)
  let n = Array(needle.utf8)
  if n.isEmpty { return true }
  if n.count > h.count { return false }
  for start in 0...(h.count - n.count) {
    var matched = true
    for i in 0..<n.count {
      if asciiToLower(h[start + i]) != asciiToLower(n[i]) {
        matched = false
        break
      }
    }
    if matched { return true }
  }
  return false
}

final class RemoteLogger {
  /// GET endpoint polled every 5s to check whether logging is enabled.
  let pollURL: String
  /// POST endpoint that state-change log entries (JSON body) are sent to.
  let logURL: String
  var loggingEnabled: Bool = false

  /// - Parameters:
  ///   - pollURL: GET endpoint polled every 5s for the current logging-enabled state.
  ///   - logURL: POST endpoint that state-change log entries are sent to.
  init(pollURL: String, logURL: String) {
    self.pollURL = pollURL
    self.logURL = logURL
  }

  // Call every 5s. Determines whether logging is enabled from the GET
  // response body text ("true"/"false" substring, case-insensitive). If
  // neither is present, the previous value is left unchanged.
  func poll() {
    let body = httpGet(url: pollURL)
    if containsCaseInsensitive(body, "false") {
      loggingEnabled = false
    } else if containsCaseInsensitive(body, "true") {
      loggingEnabled = true
    }
    print("RemoteLogger.poll: loggingEnabled=\(loggingEnabled)")
  }

  // Call whenever the light's on/off state actually changes.
  func logStateChange(on: Bool) {
    guard loggingEnabled else { return }
    let uptimeMs = Int(esp_timer_get_time() / 1000)
    let json = "{\"state\": \"\(on ? "on" : "off")\", \"uptime_ms\": \(uptimeMs)}"
    httpPost(url: logURL, jsonBody: json)
  }
}
