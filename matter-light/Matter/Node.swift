//
//  Node.swift
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// A Swift-typed handle onto the ESP-Matter root node.
protocol MatterNode {
  /// The underlying ESP-Matter node pointer this value wraps.
  var node: UnsafeMutablePointer<esp_matter.node_t> { get }
}

/// A Swift-typed handle onto an ESP-Matter endpoint.
protocol MatterEndpoint {
  /// The underlying ESP-Matter endpoint pointer this value wraps.
  var endpoint: UnsafeMutablePointer<esp_matter.endpoint_t> { get }
}

/// A `MatterEndpoint` whose device type ID is known statically, enabling
/// safe downcasting from a generic `Endpoint` via `as(_:)`.
protocol MatterConreteEndpoint: MatterEndpoint {
  static var deviceTypeId: UInt32 { get }

  /// Wraps an existing ESP-Matter endpoint pointer.
  init(_ endpoint: UnsafeMutablePointer<esp_matter.endpoint_t>)
}

/// Shared behavior for any concrete `MatterEndpoint`.
extension MatterEndpoint {
  /// This endpoint's numeric ESP-Matter endpoint ID.
  var id: UInt16 { esp_matter.endpoint.get_id(endpoint) }

  /// Looks up a cluster on this endpoint by its typed `ClusterID`.
  func cluster<Cluster: MatterCluster>(_ id: ClusterID<Cluster>) -> Cluster {
    Cluster(esp_matter.cluster.get_shim(endpoint, id.rawValue))
  }
}

/// The device's single ESP-Matter root node, plus the trampoline context that
/// forwards ESP-Matter's C attribute/identify callbacks into Swift closures.
struct RootNode: MatterNode {
  /// Signature of the Swift closure invoked for every attribute change on
  /// any endpoint of this node.
  typealias AttributeCallback = (
    MatterAttributeEvent, Endpoint, Cluster, UInt32,
    UnsafeMutablePointer<esp_matter_attr_val_t>?
  ) -> Void
  /// Signature of the Swift closure invoked when an Identify command is received.
  typealias IdentifyCallback = (
    esp_matter.identification.callback_type_t, UInt16, UInt8, UInt8
  ) -> Void

  /// Heap-allocated box holding the Swift callbacks, passed to ESP-Matter as
  /// an opaque `void *` context so its C callbacks can find their way back
  /// into Swift closures.
  final class Context {
    var attribute: AttributeCallback
    var identify: IdentifyCallback

    /// Stores the callbacks to be reached via the opaque context pointer.
    init(
      attribute: @escaping AttributeCallback,
      identify: @escaping IdentifyCallback
    ) {
      self.attribute = attribute
      self.identify = identify
    }
  }

  var node: UnsafeMutablePointer<esp_matter.node_t>
  let context: Context

  /// Registers global ESP-Matter attribute/identify callbacks (trampolining
  /// through `context`) and creates the root node, wiring `context` in as
  /// its opaque callback data. Fails if node creation fails.
  init?(
    attribute: @escaping AttributeCallback, identify: @escaping IdentifyCallback
  ) {
    var nodeConfig = esp_matter.node.config_t()
    setNodeLabelShim(&nodeConfig.root_node.basic_information, "orange cue")
    esp_matter.attribute.set_callback_shim {
      type, endpoint, cluster, attribute, value, context in
      guard let context else {
        return ESP_OK
      }
      guard let e = Endpoint(id: endpoint) else { return ESP_OK }
      guard let c = Cluster(endpoint: e, id: cluster) else { return ESP_OK }
      guard let event = MatterAttributeEvent(rawValue: type.rawValue) else {
        fatalError("Unknown event type")
      }
      let ctx = Unmanaged<Context>.fromOpaque(context).takeUnretainedValue()
      ctx.attribute(event, e, c, attribute, value)
      return ESP_OK
    }
    esp_matter.identification.set_callback {
      type, endpoint, effect, variant, context in
      guard let context else { fatalError("context must be non-nil") }
      Unmanaged<Context>.fromOpaque(context).takeUnretainedValue().identify(
        type, endpoint, effect, variant)
      return ESP_OK
    }
    guard let node = esp_matter.node.create_raw() else {
      return nil
    }

    let context = Context(attribute: attribute, identify: identify)
    withUnsafeMutablePointer(to: &nodeConfig.root_node) {
      // Transfer ownership to the node. This is a leak for now, but we don't expect nodes to be created and destroyed repeatedly.
      _ = esp_matter.endpoint.root_node.create(
        node, $0, 0x00, Unmanaged.passRetained(context).toOpaque())
    }
    self.node = node
    self.context = context
  }

  /// The node's implicit root endpoint (endpoint 0).
  var endpoint: Endpoint {
    Endpoint(esp_matter.endpoint.get(node, 0))
  }
}

/// A generic, type-erased ESP-Matter endpoint handle.
struct Endpoint: MatterEndpoint {
  var endpoint: UnsafeMutablePointer<esp_matter.endpoint_t>

  /// Wraps an existing ESP-Matter endpoint pointer.
  init(_ endpoint: UnsafeMutablePointer<esp_matter.endpoint_t>) {
    self.endpoint = endpoint
  }

  /// Looks up the endpoint with the given ID on the current root node.
  /// Fails if there is no root node yet, or no endpoint with that ID.
  init?(id: UInt16) {
    guard let root = esp_matter.node.get() else { return nil }
    guard let endpoint = esp_matter.endpoint.get(root, id) else { return nil }
    self.init(endpoint)
  }

  /// Downcasts to `T` if this endpoint advertises `T.deviceTypeId` among its
  /// device types, otherwise returns nil.
  func `as`<T: MatterConreteEndpoint>(_ type: T.Type) -> T? {
    let expected = T.deviceTypeId
    let count = Int(esp_matter.endpoint.get_device_type_count(endpoint))
    for index in 0..<count {
      var deviceTypeId: UInt32 = 0
      var deviceTypeVersion: UInt8 = 0
      guard
        esp_matter.endpoint.get_device_type_at_index(
          endpoint, index, &deviceTypeId, &deviceTypeVersion) == ESP_OK
      else { continue }
      if deviceTypeId == expected {
        return T(endpoint)
      }
    }
    return nil
  }
}

/// An "extended color light" ESP-Matter device-type endpoint (on/off,
/// dimmable, hue/saturation + color-temperature color control).
struct MatterExtendedColorLight: MatterConreteEndpoint {
  /// The ESP-Matter device type ID for an extended color light.
  static var deviceTypeId: UInt32 {
    esp_matter.endpoint.extended_color_light.get_device_type_id()
  }

  var endpoint: UnsafeMutablePointer<esp_matter.endpoint_t>

  /// Creates the endpoint under `node` with the given configuration,
  /// tagging it with `node.context` as its callback data.
  init(
    _ node: RootNode,
    configuration: esp_matter.endpoint.extended_color_light.config_t
  ) {
    var config = configuration
    endpoint = esp_matter.endpoint.extended_color_light.create(
      node.node, &config, 0x00, Unmanaged.passRetained(node.context).toOpaque())
  }

  /// Wraps an existing ESP-Matter endpoint pointer.
  init(_ endpoint: UnsafeMutablePointer<esp_matter.endpoint_t>) {
    self.endpoint = endpoint
  }

  /// The endpoint's LevelControl cluster.
  var levelControl: LevelControl {
    cluster(.levelControl)
  }

  /// The endpoint's ColorControl cluster.
  var colorControl: ColorControl {
    cluster(.colorControl)
  }

  /// The endpoint's OnOff cluster.
  var onOff: OnOff {
    cluster(.onOff)
  }
}

/// A plain "on/off light" ESP-Matter device-type endpoint (no dimming or
/// color control).
struct MatterOnOffLight: MatterConreteEndpoint {
  /// The ESP-Matter device type ID for an on/off light.
  static var deviceTypeId: UInt32 {
    esp_matter.endpoint.on_off_light.get_device_type_id()
  }

  var endpoint: UnsafeMutablePointer<esp_matter.endpoint_t>

  /// Creates the endpoint under `node` with the given configuration,
  /// tagging it with `node.context` as its callback data.
  init(
    _ node: RootNode,
    configuration: esp_matter.endpoint.on_off_light.config_t
  ) {
    var config = configuration
    endpoint = esp_matter.endpoint.on_off_light.create(
      node.node, &config, 0x00, Unmanaged.passRetained(node.context).toOpaque())
  }

  /// Wraps an existing ESP-Matter endpoint pointer.
  init(_ endpoint: UnsafeMutablePointer<esp_matter.endpoint_t>) {
    self.endpoint = endpoint
  }

  /// The endpoint's OnOff cluster.
  var onOff: OnOff {
    cluster(.onOff)
  }
}
