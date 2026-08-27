//
//  Matter.swift
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// Namespace for this project's higher-level, app-facing Matter wrapper types
/// (as opposed to the lower-level `MatterNode`/`MatterCluster`/`MatterAttribute`
/// wrappers in Node.swift/Clusters.swift/Attribute.swift).
enum Matter {}

extension Matter {
  /// The Matter root node for this device: owns the endpoint list and routes
  /// attribute-change callbacks from ESP-Matter to the matching `Endpoint`.
  class Node {
    /// Invoked when a Matter controller sends an Identify command to this node.
    var identifyHandler: (() -> Void)? = nil

    /// All endpoints registered on this node via `addEndpoint(_:)`.
    var endpoints: [Endpoint] = []

    /// Registers `endpoint` so its `eventHandler` can receive attribute
    /// change callbacks routed by `eventHandler(type:endpoint:cluster:attribute:value:)`.
    func addEndpoint(_ endpoint: Endpoint) {
      endpoints.append(endpoint)
    }

    // swift-format-ignore: NeverUseImplicitlyUnwrappedOptionals
    // This is never actually nil after init(), and inside init we want to form a callback closure that references self.
    /// The underlying ESP-Matter root node, set once during `init()`.
    var innerNode: RootNode!

    /// Initializes NVS storage and creates the underlying ESP-Matter root
    /// node, wiring its attribute/identify callbacks back to this instance.
    init() {
      // Initialize persistent storage.
      nvs_flash_init()

      // For now, leak the object, to be able to use local variables to declare it. We don't expect this object to be created and destroyed repeatedly.
      _ = Unmanaged.passRetained(self)

      // Create the actual root node object, wire up callbacks.
      let root = RootNode(
        attribute: self.eventHandler,
        identify: { _, _, _, _ in self.identifyHandler?() })
      guard let root else {
        fatalError("Failed to setup root node.")
      }
      self.innerNode = root
    }

    /// ESP-Matter's raw attribute callback, translated into a typed
    /// `Endpoint.Event` and dispatched to the matching endpoint's handler.
    /// Only reacts to `.didSet`; other event types are ignored.
    func eventHandler(
      type: MatterAttributeEvent, endpoint: __idf_main.Endpoint,
      cluster: Cluster, attribute: UInt32,
      value: UnsafeMutablePointer<esp_matter_attr_val_t>?
    ) {
      guard type == .didSet else { return }
      guard let e = self.endpoints.first(where: { $0.id == endpoint.id }) else {
        return
      }
      // esp_matter_attr_val_t.val is a C union; only the member matching .type
      // was actually initialized. Reading a wider member than what was written
      // (e.g. .u64 when only the 1-byte .b was set) picks up uninitialized
      // padding, and converting that garbage to Int traps whenever the high
      // bit happens to be set (doesn't fit in signed Int).
      let attrValue = value
      // Decoded from the C union above, according to its runtime `.type` tag.
      let value: Int
      switch attrValue?.pointee.type {
      case ESP_MATTER_VAL_TYPE_BOOLEAN, ESP_MATTER_VAL_TYPE_NULLABLE_BOOLEAN:
        value = (attrValue?.pointee.val.b ?? false) ? 1 : 0
      case ESP_MATTER_VAL_TYPE_INT8, ESP_MATTER_VAL_TYPE_NULLABLE_INT8:
        value = Int(attrValue?.pointee.val.i8 ?? 0)
      case ESP_MATTER_VAL_TYPE_UINT8, ESP_MATTER_VAL_TYPE_NULLABLE_UINT8,
        ESP_MATTER_VAL_TYPE_ENUM8, ESP_MATTER_VAL_TYPE_NULLABLE_ENUM8,
        ESP_MATTER_VAL_TYPE_BITMAP8, ESP_MATTER_VAL_TYPE_NULLABLE_BITMAP8:
        value = Int(attrValue?.pointee.val.u8 ?? 0)
      case ESP_MATTER_VAL_TYPE_INT16, ESP_MATTER_VAL_TYPE_NULLABLE_INT16:
        value = Int(attrValue?.pointee.val.i16 ?? 0)
      case ESP_MATTER_VAL_TYPE_UINT16, ESP_MATTER_VAL_TYPE_NULLABLE_UINT16,
        ESP_MATTER_VAL_TYPE_ENUM16, ESP_MATTER_VAL_TYPE_NULLABLE_ENUM16,
        ESP_MATTER_VAL_TYPE_BITMAP16, ESP_MATTER_VAL_TYPE_NULLABLE_BITMAP16:
        value = Int(attrValue?.pointee.val.u16 ?? 0)
      case ESP_MATTER_VAL_TYPE_INT32, ESP_MATTER_VAL_TYPE_NULLABLE_INT32:
        value = Int(attrValue?.pointee.val.i32 ?? 0)
      case ESP_MATTER_VAL_TYPE_UINT32, ESP_MATTER_VAL_TYPE_NULLABLE_UINT32,
        ESP_MATTER_VAL_TYPE_BITMAP32, ESP_MATTER_VAL_TYPE_NULLABLE_BITMAP32:
        value = Int(attrValue?.pointee.val.u32 ?? 0)
      case ESP_MATTER_VAL_TYPE_INT64, ESP_MATTER_VAL_TYPE_NULLABLE_INT64:
        value = Int(truncatingIfNeeded: attrValue?.pointee.val.i64 ?? 0)
      case ESP_MATTER_VAL_TYPE_UINT64, ESP_MATTER_VAL_TYPE_NULLABLE_UINT64:
        value = Int(truncatingIfNeeded: attrValue?.pointee.val.u64 ?? 0)
      default:
        value = 0
      }
      guard let a = Endpoint.Attribute(cluster: cluster, attribute: attribute)
      else { return }
      e.eventHandler?(Endpoint.Event(type: type, attribute: a, value: value))
    }
  }
}

extension Matter {
  /// Base class for a Matter endpoint (e.g. a light) attached to a `Node`.
  /// Subclasses create the concrete ESP-Matter endpoint in their initializer.
  class Endpoint {
    /// Registers this endpoint with ESP-Matter's callback context. Subclasses
    /// must call this via `super.init(node:)` before creating their endpoint.
    init(node: Node) {
      // For now, leak the object, to be able to use local variables to declare it. We don't expect this object to be created and destroyed repeatedly.
      _ = Unmanaged.passRetained(self)
    }

    /// The ESP-Matter endpoint ID, set by the subclass after creating the
    /// underlying endpoint.
    var id: Int = 0

    /// Invoked whenever an attribute on this endpoint changes.
    var eventHandler: ((Event) -> Void)? = nil

    /// Which ColorControl attribute changed, for `.colorControl` events.
    enum ColorControlAttribute {
      case currentHue
      case currentSaturation
      case currentX
      case currentY
      case colorTemperatureMireds
      case colorMode
    }

    /// Identifies which cluster/attribute pair a raw ESP-Matter callback
    /// refers to, resolved by cluster type then attribute ID.
    enum Attribute {
      case onOff
      case levelControl
      case colorControl(ColorControlAttribute)
      case unknown(UInt32)

      /// Resolves a raw ESP-Matter `(cluster, attribute)` pair into a typed
      /// `Attribute` case by first identifying the cluster type, then
      /// matching the attribute ID within that cluster. Returns nil if the
      /// cluster is a known type but the attribute ID isn't one this app
      /// recognizes.
      init?(cluster: Cluster, attribute: UInt32) {
        if cluster.as(OnOff.self) != nil {
          switch attribute {
          case OnOff.AttributeID<OnOff.OnOffState>.state.rawValue: self = .onOff
          default: return nil
          }
        } else if cluster.as(LevelControl.self) != nil {
          switch attribute {
          case LevelControl.AttributeID<LevelControl.CurrentLevel>.currentLevel
            .rawValue:
            self = .levelControl
          default: return nil
          }
        } else if cluster.as(ColorControl.self) != nil {
          switch attribute {
          case ColorControl.AttributeID<ColorControl.CurrentHue>.currentHue
            .rawValue:
            self = .colorControl(.currentHue)
          case ColorControl.AttributeID<ColorControl.CurrentSaturation>
            .currentSaturation.rawValue:
            self = .colorControl(.currentSaturation)
          case ColorControl.AttributeID<ColorControl.CurrentX>.currentX.rawValue:
            self = .colorControl(.currentX)
          case ColorControl.AttributeID<ColorControl.CurrentY>.currentY.rawValue:
            self = .colorControl(.currentY)
          case ColorControl.AttributeID<ColorControl.ColorTemperatureMireds>
            .colorTemperatureMireds.rawValue:
            self = .colorControl(.colorTemperatureMireds)
          case ColorControl.AttributeID<ColorControl.ColorMode>.colorMode
            .rawValue:
            self = .colorControl(.colorMode)
          default: return nil
          }
        } else {
          self = .unknown(attribute)
        }
      }
    }

    /// A decoded attribute-change notification delivered to `eventHandler`.
    struct Event {
      var type: MatterAttributeEvent
      var attribute: Attribute
      var value: Int
    }
  }
}

extension Matter {
  /// An "extended color light" endpoint: on/off, dimmable, and supporting
  /// both hue/saturation and color-temperature color control.
  class ExtendedColorLight: Endpoint {
    /// Creates the ESP-Matter extended-color-light endpoint with a default
    /// on/off state, brightness, and color-temperature color mode, then
    /// enables the hue/saturation color feature.
    override init(node: Node) {
      super.init(node: node)

      var lightConfig = esp_matter.endpoint.extended_color_light.config_t()
      lightConfig.on_off.on_off = true
      lightConfig.level_control.current_level = .init(64)
      lightConfig.color_control.color_mode =
        chip.app.Clusters.ColorControl.ColorMode.colorTemperature.rawValue
      lightConfig.color_control.enhanced_color_mode =
        chip.app.Clusters.ColorControl.ColorMode.colorTemperature.rawValue

      let light = MatterExtendedColorLight(
        node.innerNode, configuration: lightConfig)
      self.id = Int(light.id)

      var hsv = esp_matter.cluster.color_control.feature.hue_saturation
        .config_t()
      hsv.current_hue = 255
      hsv.current_saturation = 255
      light.colorControl.add(hsv)
    }
  }
}

extension Matter {
  /// A plain on/off light endpoint (no dimming or color control).
  class OnOffLight: Endpoint {
    /// Creates the ESP-Matter on/off-light endpoint, defaulting it to on.
    override init(node: Node) {
      super.init(node: node)

      var lightConfig = esp_matter.endpoint.on_off_light.config_t()
      lightConfig.on_off.on_off = true

      let light = MatterOnOffLight(node.innerNode, configuration: lightConfig)
      self.id = Int(light.id)
    }
  }
}

extension Matter {
  /// Owns the root node and drives the ESP-Matter stack's start/lifecycle.
  class Application {
    /// The root node this application serves; set before calling `start()`.
    var rootNode: Node? = nil

    /// Retains this instance so it survives for the lifetime of the firmware.
    init() {
      // For now, leak the object, to be able to use local variables to declare
      // it. We don't expect this object to be created and destroyed repeatedly.
      _ = Unmanaged.passRetained(self)
    }

    /// Starts the ESP-Matter stack, reopening BLE commissioning if the
    /// device's fabric was removed, and prints the onboarding QR/manual codes.
    func start() {
      /// ESP-Matter device-event callback: reopens commissioning when the
      /// device's Matter fabric is removed (e.g. after a factory reset by a
      /// controller), so it can be paired again.
      func callback(
        event: UnsafePointer<chip.DeviceLayer.ChipDeviceEvent>?, context: Int
      ) {
        // Ignore callback if event not set.
        guard let event else { return }
        switch Int(event.pointee.Type) {
        case chip.DeviceLayer.DeviceEventType.kFabricRemoved:
          recomissionFabric()
        default: break
        }
      }
      esp_matter.start(callback, 0)
      printOnboardingCodes()
    }
  }
}

/// Logs a `Matter.Endpoint.Attribute` in a compact, readable form.
func print(_ a: Matter.Endpoint.Attribute) {
  switch a {
  case .onOff: print("onOff")
  case .levelControl: print("levelControl")
  case .colorControl(let a):
    print("colorControl(", terminator: "")
    switch a {
    case .currentHue: print("currentHue", terminator: "")
    case .currentSaturation: print("currentSaturation", terminator: "")
    case .currentX: print("currentX", terminator: "")
    case .currentY: print("currentY", terminator: "")
    case .colorTemperatureMireds:
      print("colorTemperatureMireds", terminator: "")
    case .colorMode: print("colorMode", terminator: "")
    }
    print(")")
  case .unknown: print("unknown")
  }
}
