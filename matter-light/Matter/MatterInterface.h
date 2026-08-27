//
//  MatterInterface.h
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

// GNU C++ interfaces do not work well with Swift for certain types, so let's use some simple C++ shims.
// For example, uint32_t gets imported as UInt and not CUnsignedLong (as defined in ESP IDF).
namespace esp_matter {
  namespace attribute {
    // Function-pointer type for the attribute callback, using `unsigned int`
    // instead of ESP-IDF's uint32_t/cluster/attribute ID typedefs so it
    // imports into Swift cleanly.
    typedef esp_err_t (*callback_t_shim)(callback_type_t type, uint16_t endpoint_id, unsigned int cluster_id,
                                         unsigned int attribute_id, esp_matter_attr_val_t *val, void *priv_data);
    // Registers `callback` as the global attribute-change callback (Swift-friendly wrapper around set_callback).
    esp_err_t set_callback_shim(callback_t_shim callback);
  }

  namespace cluster {
    // Looks up a cluster on `endpoint` by numeric ID (Swift-friendly wrapper around get).
    cluster_t *get_shim(endpoint_t *endpoint, unsigned int cluster_id);
  }

  namespace attribute {
    // Looks up an attribute on `cluster` by numeric ID (Swift-friendly wrapper around get).
    attribute_t *get_shim(cluster_t *cluster, unsigned int attribute_id);
  }
}

// Recomissioning causes failures with reference semantics so this is done as a function implemented in C++.
// Ideally this would be done by changing some of the headers in ESP Matter to have proper Swift annotations.
// Reopens BLE commissioning if the device currently has no Matter fabric
// (e.g. after a controller-initiated factory reset), so it can be paired again.
void recomissionFabric();

// Prints the QR code URL and manual pairing code to the serial console, same as
// PrintOnboardingCodes(chip::RendezvousInformationFlags(CONFIG_RENDEZVOUS_MODE))
// in the official ESP32 lighting-app example.
void printOnboardingCodes();

// basic_information::config_t.node_label is a fixed C char array, which Swift's
// C++ interop imports as a tuple rather than something string-assignable, so
// setting it needs a small shim.
// Copies `label` into `config->node_label`, truncating and NUL-terminating to fit the fixed-size buffer.
void setNodeLabelShim(esp_matter::cluster::basic_information::config_t *config, const char *label);
