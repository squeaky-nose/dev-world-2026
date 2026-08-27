//
//  Led.swift
//  hello-morse
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

// A simple "overlay" to provide nicer APIs in Swift
struct Led {
  /// The GPIO pin driving the LED, configured as an output.
  var ledPin: gpio_num_t

  /// Resets the given GPIO pin and configures it as an output for the LED.
  /// Fails fast (`fatalError`) if either GPIO call reports an error, since
  /// there's no way to drive the LED without them succeeding.
  init(gpioPin: Int) {
    ledPin = gpio_num_t(Int32(gpioPin))

    guard gpio_reset_pin(ledPin) == ESP_OK else {
      fatalError("cannot reset led")
    }

    guard gpio_set_direction(ledPin, GPIO_MODE_OUTPUT) == ESP_OK else {
      fatalError("cannot reset led")
    }
  }

  /// Turns the LED on (`true`) or off (`false`).
  func setLed(value: Bool) {
    let level: UInt32 = value ? 1 : 0
    gpio_set_level(ledPin, level)
  }
}
