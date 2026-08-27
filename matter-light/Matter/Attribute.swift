//
//  Attribute.swift
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// A Swift-typed handle onto one ESP-Matter attribute, keyed by its C pointer.
protocol MatterAttribute {
  /// The underlying ESP-Matter attribute pointer this value wraps.
  var attribute: UnsafeMutablePointer<esp_matter.attribute_t> { get }

  /// Wraps an existing ESP-Matter attribute pointer.
  init(attribute: UnsafeMutablePointer<esp_matter.attribute_t>)
}

/// Shared behavior for any concrete `MatterAttribute`.
extension MatterAttribute {
  /// Reads the attribute's current value out of ESP-Matter's storage.
  var value: esp_matter_attr_val_t {
    var val = esp_matter_attr_val_t()
    esp_matter.attribute.get_val(attribute, &val)
    return val
  }
}

/// Mirrors ESP-Matter's `attribute::callback_type_t`: the point in an
/// attribute access/mutation where a callback fires.
enum MatterAttributeEvent: esp_matter.attribute.callback_type_t.RawValue {
  case willSet = 0
  case didSet = 1
  case read = 2
  case write = 3

  /// Human-readable name for logging.
  var description: StaticString {
    switch self {
    case .willSet: "willSet"
    case .didSet: "didSet"
    case .read: "read"
    case .write: "write"
    }
  }
}

/// Logs a `MatterAttributeEvent` by its `description`.
func print(_ e: MatterAttributeEvent) {
  print(e.description)
}

/// A cluster-scoped attribute identifier, raw-valued as the numeric ESP-Matter
/// attribute ID and tied to the concrete `MatterAttribute` type it addresses.
protocol MatterAttributeID: RawRepresentable where RawValue == UInt32 {
  associatedtype Attribute: MatterAttribute
}

/// LevelControl cluster attributes.
extension LevelControl {
  /// The LevelControl cluster's `CurrentLevel` attribute (0x0000).
  struct CurrentLevel: MatterAttribute {
    var attribute: UnsafeMutablePointer<esp_matter.attribute_t>
  }
}

/// ColorControl cluster attributes.
extension ColorControl {
  /// The ColorControl cluster's `CurrentHue` attribute (0x0000).
  struct CurrentHue: MatterAttribute {
    var attribute: UnsafeMutablePointer<esp_matter.attribute_t>
  }

  /// The ColorControl cluster's `CurrentSaturation` attribute (0x0001).
  struct CurrentSaturation: MatterAttribute {
    var attribute: UnsafeMutablePointer<esp_matter.attribute_t>
  }

  /// The ColorControl cluster's `CurrentX` attribute (0x0003).
  struct CurrentX: MatterAttribute {
    var attribute: UnsafeMutablePointer<esp_matter.attribute_t>
  }

  /// The ColorControl cluster's `CurrentY` attribute (0x0004).
  struct CurrentY: MatterAttribute {
    var attribute: UnsafeMutablePointer<esp_matter.attribute_t>
  }

  /// The ColorControl cluster's `ColorTemperatureMireds` attribute (0x0007).
  struct ColorTemperatureMireds: MatterAttribute {
    var attribute: UnsafeMutablePointer<esp_matter.attribute_t>
  }

  /// The ColorControl cluster's `ColorMode` attribute (0x0008).
  struct ColorMode: MatterAttribute {
    var attribute: UnsafeMutablePointer<esp_matter.attribute_t>
  }
}

/// OnOff cluster attributes.
extension OnOff {
  /// The OnOff cluster's `OnOff` state attribute (0x0000).
  struct OnOffState: MatterAttribute {
    var attribute: UnsafeMutablePointer<esp_matter.attribute_t>
  }
}
