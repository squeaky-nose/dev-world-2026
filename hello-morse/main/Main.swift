//
//  Main.swift
//  hello-morse
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//
// The code will spell out a message in Morse code on the onboard LED
// of the XIAO ESP32C6 (GPIO15).

/// The message that gets spelled out in Morse code on the LED, forever.
let message = "Hello DevWorld 2026!"

// Duration of one Morse "dot", in milliseconds. A dash is 3 units, the gap
// between symbols in a letter is 1 unit, between letters is 3 units, and
// between words is 7 units.
let unitMs: UInt32 = 200

/// Returns the Morse code (dots and dashes) for a single ASCII byte, or
/// `nil` if the byte has no Morse representation (treated by callers as a
/// word gap).
//
// Operates on raw UTF-8 bytes rather than `Character`: comparing `Character`
// values pulls in the stdlib's Unicode grapheme-breaking/normalization
// tables, which aren't linked into this freestanding embedded build. The
// message and Morse alphabet are all plain ASCII, so bytes are sufficient.
func morse(for byte: UInt8) -> String? {
  switch byte {
  case UInt8(ascii: "A"), UInt8(ascii: "a"): return ".-"
  case UInt8(ascii: "B"), UInt8(ascii: "b"): return "-..."
  case UInt8(ascii: "C"), UInt8(ascii: "c"): return "-.-."
  case UInt8(ascii: "D"), UInt8(ascii: "d"): return "-.."
  case UInt8(ascii: "E"), UInt8(ascii: "e"): return "."
  case UInt8(ascii: "F"), UInt8(ascii: "f"): return "..-."
  case UInt8(ascii: "G"), UInt8(ascii: "g"): return "--."
  case UInt8(ascii: "H"), UInt8(ascii: "h"): return "...."
  case UInt8(ascii: "I"), UInt8(ascii: "i"): return ".."
  case UInt8(ascii: "J"), UInt8(ascii: "j"): return ".---"
  case UInt8(ascii: "K"), UInt8(ascii: "k"): return "-.-"
  case UInt8(ascii: "L"), UInt8(ascii: "l"): return ".-.."
  case UInt8(ascii: "M"), UInt8(ascii: "m"): return "--"
  case UInt8(ascii: "N"), UInt8(ascii: "n"): return "-."
  case UInt8(ascii: "O"), UInt8(ascii: "o"): return "---"
  case UInt8(ascii: "P"), UInt8(ascii: "p"): return ".--."
  case UInt8(ascii: "Q"), UInt8(ascii: "q"): return "--.-"
  case UInt8(ascii: "R"), UInt8(ascii: "r"): return ".-."
  case UInt8(ascii: "S"), UInt8(ascii: "s"): return "..."
  case UInt8(ascii: "T"), UInt8(ascii: "t"): return "-"
  case UInt8(ascii: "U"), UInt8(ascii: "u"): return "..-"
  case UInt8(ascii: "V"), UInt8(ascii: "v"): return "...-"
  case UInt8(ascii: "W"), UInt8(ascii: "w"): return ".--"
  case UInt8(ascii: "X"), UInt8(ascii: "x"): return "-..-"
  case UInt8(ascii: "Y"), UInt8(ascii: "y"): return "-.--"
  case UInt8(ascii: "Z"), UInt8(ascii: "z"): return "--.."
  case UInt8(ascii: "0"): return "-----"
  case UInt8(ascii: "1"): return ".----"
  case UInt8(ascii: "2"): return "..---"
  case UInt8(ascii: "3"): return "...--"
  case UInt8(ascii: "4"): return "....-"
  case UInt8(ascii: "5"): return "....."
  case UInt8(ascii: "6"): return "-...."
  case UInt8(ascii: "7"): return "--..."
  case UInt8(ascii: "8"): return "---.."
  case UInt8(ascii: "9"): return "----."
  case UInt8(ascii: "!"): return "-.-.--"
  case UInt8(ascii: "-"): return "-....-"
  default: return nil  // Unrecognized bytes (including spaces) become a word gap.
  }
}

/// Blocks the current FreeRTOS task for approximately `ms` milliseconds,
/// converting from milliseconds to ticks using the configured tick rate.
func delay(ms: UInt32) {
  vTaskDelay(ms / (1000 / UInt32(configTICK_RATE_HZ)))
}

/// Blinks the LED once for a single Morse symbol: a dash (`-`) is held 3
/// units, anything else (a dot) is held 1 unit.
func blinkSymbol(_ symbolByte: UInt8, led: Led) {
  let durationUnits: UInt32 = symbolByte == UInt8(ascii: "-") ? 3 : 1  // dash = 3 units, dot = 1 unit
  led.setLed(value: true)
  delay(ms: unitMs * durationUnits)
  led.setLed(value: false)
}

/// Blinks out a full Morse `code` string (e.g. `".-"` for "A") on `led`,
/// inserting the inter-symbol gap between symbols but not before the first.
func blinkMorse(_ code: String, led: Led) {
  var isFirstSymbol = true  // suppresses the leading inter-symbol gap
  for symbolByte in code.utf8 {
    if !isFirstSymbol {
      delay(ms: unitMs)  // Gap between symbols within a letter.
    }
    isFirstSymbol = false
    blinkSymbol(symbolByte, led: led)
  }
}

/// Logger used for the blink loop's status/progress messages.
let logger = Logger(subsystem: "com.example.hello-world", category: "morse")

/// Firmware entry point, exported under the C symbol ESP-IDF calls to start
/// the app. Never returns: after logging startup, it blinks `message` in
/// Morse code on the onboard LED in an infinite loop.
@_cdecl("app_main")
func main() {
  delay(ms: unitMs * 10)  // Wait for debugger to attach.
  logger.info("Starting with \(message)")

  let led = Led(gpioPin: 15)

  while true {
    logger.notice("--- start: \(message) ---")
    for byte in message.utf8 {
      if let code = morse(for: byte) {
        let charString = String(decoding: [byte], as: UTF8.self)  // byte, as text, for the log line
        logger.debug("\(charString): \(code)")
        blinkMorse(code, led: led)
        delay(ms: unitMs * 3)  // Gap between letters.
      } else {
        logger.debug("(word gap)")
        delay(ms: unitMs * 7)  // Gap between words.
      }
    }
    logger.notice("--- end ---")
    delay(ms: unitMs * 10)  // Pause before repeating the message.
  }
}
