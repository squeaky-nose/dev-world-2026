//
//  Main.swift
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// Firmware entry point (called by ESP-IDF as `app_main`). Sets up the LED,
/// remote logger, and Matter on/off-light endpoint, wires the light's on/off
/// state to the LED and remote logger, starts the Matter application, then
/// runs forever, polling the remote logger every 5s.
@_cdecl("app_main")
func main() {
  print("Hello, Embedded Swift! (Matter Smart Light on ESP32-C6)")

  let led = LED(gpioPin: 15)

  let remoteLogger = RemoteLogger(
    pollURL: "https://m8jrbrlmd4.rbmock.dev/",  // GET
    logURL: "https://m8jrbrlmd4.rbmock.dev/log")  // POST

  // (1) Create a Matter root node
  let rootNode = Matter.Node()
  rootNode.identifyHandler = {
    print("identify")
  }

  // (2) Create a "light" endpoint
  let lightEndpoint = Matter.OnOffLight(node: rootNode)
  lightEndpoint.eventHandler = { event in
    print("lightEndpoint.eventHandler:")
    print(event.attribute)
    print(event.value)

    switch event.attribute {
    case .onOff:
      // OnOff attribute value is decoded as an Int (1 = on, 0 = off) by Matter.Node.eventHandler.
      let isOn = event.value == 1
      led.setLed(value: isOn)
      remoteLogger.logStateChange(on: isOn)

    default:
      break
    }
  }

  // (3) Add the endpoint to the node
  rootNode.addEndpoint(lightEndpoint)

  // (4) Provide the node to a Matter application and start it
  let app = Matter.Application()
  app.rootNode = rootNode
  app.start()

  // Keep local variables alive (also doubles as the remote-log poll loop).
  // Workaround for issue #10: https://github.com/swiftlang/swift-matter-examples/issues/10
  var secondsSinceLastPoll = 0
  while true {
    sleep(1)
    secondsSinceLastPoll += 1
    if secondsSinceLastPoll >= 5 {
      secondsSinceLastPoll = 0
      remoteLogger.poll()
    }
  }
}
