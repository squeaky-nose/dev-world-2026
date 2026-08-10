// Controls the ESP32-C6 LED via a plain GPIO digital output (on/off only).
struct LED {
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
    // Active-low: this LED is wired so GPIO LOW turns it on.
    let level: UInt32 = value ? 0 : 1
    gpio_set_level(ledPin, level)
  }
}
