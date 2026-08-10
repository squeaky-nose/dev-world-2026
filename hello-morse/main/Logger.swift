//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

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
  let tag: String

  init(subsystem: String = "", category: String) {
    self.tag = category
  }

  // `file`/`line` default to the call site via compiler magic (`#fileID`,
  // `#line`), so existing call sites like `logger.info("msg")` are
  // unaffected -- the extra arguments only show up if a caller wants to
  // override them.

  func trace(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_verbose)
  }

  func debug(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_debug)
  }

  func info(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_info)
  }

  func notice(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_info)
  }

  func warning(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_warn)
  }

  func error(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_error)
  }

  func critical(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_error)
  }

  func fault(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_error)
  }

  func log(_ message: String, file: String = #fileID, line: Int = #line) {
    write(message, file: file, line: line, using: swift_log_info)
  }

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
