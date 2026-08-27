//
//  Logger.swift
//  hello-morse
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

// A small shim shaped like `os.Logger` (from Apple's `import os`), backed by
// ESP-IDF's `esp_log.h` instead of Darwin's unified logging. `os.log` itself
// isn't available here -- it talks to the Darwin kernel's logd, which
// doesn't exist on this chip.
//
// Call sites that just interpolate plain values, e.g.
// `logger.info("byte: \(byte)")`, are source-compatible with real
// `os.Logger`. What's NOT supported: `OSLogMessage`'s privacy-annotated
// interpolation (`\(value, privacy: .public)`) -- that's Darwin-specific
// machinery this shim doesn't implement, so those call sites won't compile
// as-is.
struct Logger {
  /// The ESP-IDF log tag this logger writes under (mirrors `os.Logger`'s
  /// `category`; `subsystem` is accepted for source compatibility but unused).
  let tag: String

  /// Creates a logger that tags its output with `category`. `subsystem` is
  /// ignored -- ESP-IDF logging has no equivalent concept.
  init(subsystem: String = "", category: String) {
    self.tag = category
  }

  // `file`/`line` default to the call site via compiler magic (`#fileID`,
  // `#line`), so existing call sites like `logger.info("msg")` are
  // unaffected -- the extra arguments only show up if a caller wants to
  // override them.

  /// Logs at verbose/trace level (mapped to ESP-IDF's `ESP_LOGV`).
  func trace(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_verbose)
  }

  /// Logs at debug level (mapped to ESP-IDF's `ESP_LOGD`).
  func debug(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_debug)
  }

  /// Logs at info level (mapped to ESP-IDF's `ESP_LOGI`).
  func info(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_info)
  }

  /// Logs at notice level. ESP-IDF has no distinct "notice" level, so this
  /// maps to the same `ESP_LOGI` as `info`.
  func notice(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_info)
  }

  /// Logs at warning level (mapped to ESP-IDF's `ESP_LOGW`).
  func warning(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_warn)
  }

  /// Logs at error level (mapped to ESP-IDF's `ESP_LOGE`).
  func error(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_error)
  }

  /// Logs at critical level. ESP-IDF has no distinct "critical" level, so
  /// this maps to the same `ESP_LOGE` as `error`.
  func critical(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_error)
  }

  /// Logs at fault level. ESP-IDF has no distinct "fault" level, so this
  /// maps to the same `ESP_LOGE` as `error`.
  func fault(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_error)
  }

  /// Logs at the default level (mapped to ESP-IDF's `ESP_LOGI`, matching
  /// `os.Logger`'s default).
  func log(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_info)
  }

  /// Formats `message` with its call-site file/line prefix and forwards it,
  /// as C strings, to the given ESP-IDF log wrapper.
  private func write(
    _ message: String,
    file: String,
    line: Int,
    using logFn: (UnsafePointer<CChar>, UnsafePointer<CChar>) -> Void
  ) {
    let formatted = "\(file):\(line): \(message)"
    tag.withCString { tagPtr in
      formatted.withCString { messagePtr in
        logFn(tagPtr, messagePtr)
      }
    }
  }
}
