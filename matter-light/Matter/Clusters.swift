//
//  Clusters.swift
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// A Swift-typed handle onto one ESP-Matter cluster, keyed by its C pointer.
protocol MatterCluster {
  /// The underlying ESP-Matter cluster pointer this value wraps.
  var cluster: UnsafeMutablePointer<esp_matter.cluster_t> { get }

  /// Wraps an existing ESP-Matter cluster pointer.
  init(_ cluster: UnsafeMutablePointer<esp_matter.cluster_t>)
}

/// Shared behavior for any concrete `MatterCluster`.
extension MatterCluster {
  /// Looks up this cluster type on `endpoint` by numeric cluster ID, failing
  /// if the endpoint has no cluster with that ID.
  init?(endpoint: some MatterEndpoint, id: UInt32) {
    guard let cluster = esp_matter.cluster.get_shim(endpoint.endpoint, id)
    else {
      return nil
    }
    self.init(cluster)
  }
}

/// A `MatterCluster` whose numeric cluster ID is known statically, enabling
/// safe downcasting from the generic `Cluster` wrapper via `as(_:)`.
protocol MatterConcreteCluster: MatterCluster {
  static var clusterTypeId: ClusterID<Self> { get }
}

/// A cluster's numeric Matter cluster ID, typed to the specific
/// `MatterCluster` it identifies so it can't be mismatched at compile time.
struct ClusterID<Cluster: MatterCluster>: RawRepresentable {
  var rawValue: UInt32

  /// Identify cluster ID (0x0003).
  static var identify: ClusterID<Identify> { .init(rawValue: 0x0000_0003) }
  /// OnOff cluster ID (0x0006).
  static var onOff: ClusterID<OnOff> { .init(rawValue: 0x0000_0006) }
  /// LevelControl cluster ID (0x0008).
  static var levelControl: ClusterID<LevelControl> {
    .init(rawValue: 0x0000_0008)
  }
  /// ColorControl cluster ID (0x0300).
  static var colorControl: ClusterID<ColorControl> {
    .init(rawValue: 0x0000_0300)
  }
}

/// A type-erased handle onto any ESP-Matter cluster, downcastable to a
/// concrete cluster type (e.g. `OnOff`) via `as(_:)` once its ID is known.
struct Cluster: MatterCluster {
  var cluster: UnsafeMutablePointer<esp_matter.cluster_t>

  init(_ cluster: UnsafeMutablePointer<esp_matter.cluster_t>) {
    self.cluster = cluster
  }

  /// Downcasts to `T` if this cluster's runtime ID matches `T.clusterTypeId`,
  /// otherwise returns nil.
  func `as`<T: MatterConcreteCluster>(_ type: T.Type) -> T? {
    let expected = T.clusterTypeId
    let id = esp_matter.cluster.get_id(cluster)
    if id == expected.rawValue {
      return T(cluster)
    }
    return nil
  }
}

/// The Identify cluster (0x0003).
struct Identify: MatterConcreteCluster {
  static var clusterTypeId: ClusterID<Self> { .identify }
  /// An attribute ID scoped to the Identify cluster.
  struct AttributeID<Attribute: MatterAttribute>: MatterAttributeID {
    var rawValue: UInt32
  }

  var cluster: UnsafeMutablePointer<esp_matter.cluster_t>

  init(_ cluster: UnsafeMutablePointer<esp_matter.cluster_t>) {
    self.cluster = cluster
  }

  /// Looks up an attribute on this cluster by its `AttributeID`.
  func attribute<Attribute: MatterAttribute>(_ id: AttributeID<Attribute>)
    -> Attribute
  {
    Attribute(attribute: esp_matter.attribute.get_shim(cluster, id.rawValue))
  }
}

/// The OnOff cluster (0x0006): the light's on/off switch state.
struct OnOff: MatterConcreteCluster {
  static var clusterTypeId: ClusterID<Self> { .onOff }
  /// An attribute ID scoped to the OnOff cluster.
  struct AttributeID<Attribute: MatterAttribute>: MatterAttributeID {
    var rawValue: UInt32

    /// The `OnOff` state attribute ID (0x0000).
    static var state: AttributeID<OnOffState> { .init(rawValue: 0x0000_0000) }
  }

  var cluster: UnsafeMutablePointer<esp_matter.cluster_t>

  init(_ cluster: UnsafeMutablePointer<esp_matter.cluster_t>) {
    self.cluster = cluster
  }

  /// Looks up an attribute on this cluster by its `AttributeID`.
  func attribute<Attribute: MatterAttribute>(_ id: AttributeID<Attribute>)
    -> Attribute
  {
    Attribute(attribute: esp_matter.attribute.get_shim(cluster, id.rawValue))
  }

  /// The cluster's `OnOff` state attribute.
  var state: OnOffState { attribute(.state) }
}

/// The LevelControl cluster (0x0008): brightness/dimming level.
struct LevelControl: MatterConcreteCluster {
  static var clusterTypeId: ClusterID<Self> { .levelControl }
  /// An attribute ID scoped to the LevelControl cluster.
  struct AttributeID<Attribute: MatterAttribute>: MatterAttributeID {
    var rawValue: UInt32

    /// The `CurrentLevel` attribute ID (0x0000).
    static var currentLevel: AttributeID<CurrentLevel> {
      .init(rawValue: 0x0000_0000)
    }
  }

  var cluster: UnsafeMutablePointer<esp_matter.cluster_t>

  init(_ cluster: UnsafeMutablePointer<esp_matter.cluster_t>) {
    self.cluster = cluster
  }

  /// Looks up an attribute on this cluster by its `AttributeID`.
  func attribute<Attribute: MatterAttribute>(_ id: AttributeID<Attribute>)
    -> Attribute
  {
    Attribute(attribute: esp_matter.attribute.get_shim(cluster, id.rawValue))
  }

  /// The cluster's `CurrentLevel` attribute.
  var currentLevel: CurrentLevel { attribute(.currentLevel) }
}

/// The ColorControl cluster (0x0300): hue/saturation, XY, and color
/// temperature representations of the light's color.
struct ColorControl: MatterConcreteCluster {
  static var clusterTypeId: ClusterID<Self> { .colorControl }
  /// An attribute ID scoped to the ColorControl cluster.
  struct AttributeID<Attribute: MatterAttribute>: MatterAttributeID {
    var rawValue: UInt32

    /// The `CurrentHue` attribute ID (0x0000).
    static var currentHue: AttributeID<CurrentHue> {
      .init(rawValue: 0x0000_0000)
    }
    /// The `CurrentSaturation` attribute ID (0x0001).
    static var currentSaturation: AttributeID<CurrentSaturation> {
      .init(rawValue: 0x0000_0001)
    }
    /// The `CurrentX` attribute ID (0x0003).
    static var currentX: AttributeID<CurrentX> { .init(rawValue: 0x0000_0003) }
    /// The `CurrentY` attribute ID (0x0004).
    static var currentY: AttributeID<CurrentY> { .init(rawValue: 0x0000_0004) }
    /// The `ColorTemperatureMireds` attribute ID (0x0007).
    static var colorTemperatureMireds: AttributeID<ColorTemperatureMireds> {
      .init(rawValue: 0x0000_0007)
    }
    /// The `ColorMode` attribute ID (0x0008).
    static var colorMode: AttributeID<ColorMode> {
      .init(rawValue: 0x0000_0008)
    }
  }

  var cluster: UnsafeMutablePointer<esp_matter.cluster_t>

  init(_ cluster: UnsafeMutablePointer<esp_matter.cluster_t>) {
    self.cluster = cluster
  }

  /// Looks up an attribute on this cluster by its `AttributeID`.
  func attribute<Attribute: MatterAttribute>(_ id: AttributeID<Attribute>)
    -> Attribute
  {
    Attribute(attribute: esp_matter.attribute.get_shim(cluster, id.rawValue))
  }

  /// The cluster's `CurrentHue` attribute.
  var currentHue: CurrentHue { attribute(.currentHue) }
  /// The cluster's `CurrentSaturation` attribute.
  var currentSaturation: CurrentSaturation { attribute(.currentSaturation) }
  /// The cluster's `CurrentX` attribute.
  var currentX: CurrentX { attribute(.currentX) }
  /// The cluster's `CurrentY` attribute.
  var currentY: CurrentY { attribute(.currentY) }
  /// The cluster's `ColorTemperatureMireds` attribute.
  var colorTemperatureMireds: ColorTemperatureMireds {
    attribute(.colorTemperatureMireds)
  }
  /// The cluster's `ColorMode` attribute.
  var colorMode: ColorMode { attribute(.colorMode) }

  /// Enables the hue/saturation color feature on this cluster with the given
  /// starting configuration.
  func add(
    _ config: esp_matter.cluster.color_control.feature.hue_saturation.config_t
  ) {
    var cfg = config
    esp_matter.cluster.color_control.feature.hue_saturation.add(cluster, &cfg)
  }
}
