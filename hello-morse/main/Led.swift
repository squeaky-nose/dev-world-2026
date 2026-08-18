//
//  Led.swift
//  hello-morse
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

// A simple "overlay" to provide nicer APIs in Swift
struct Led {
  var ledPin: gpio_num_t
  init(gpioPin: Int) {
    ledPin = gpio_num_t(Int32(gpioPin))

    guard gpio_reset_pin(ledPin) == ESP_OK else {
      fatalError("cannot reset led")
    }

    guard gpio_set_direction(ledPin, GPIO_MODE_OUTPUT) == ESP_OK else {
      fatalError("cannot reset led")
    }
  }
  func setLed(value: Bool) {
    let level: UInt32 = value ? 1 : 0
    gpio_set_level(ledPin, level)
  }
}
