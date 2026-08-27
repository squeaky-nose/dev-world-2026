//
//  MatterInterface.cpp
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

#include "BridgingHeader.h"
#include <setup_payload/OnboardingCodesUtil.h>
#include <cstring>

// Forwards to esp_matter's set_callback with the shim's `unsigned int`-based
// signature cast back to the library's own callback_t.
esp_err_t esp_matter::attribute::set_callback_shim(callback_t_shim callback) {
  return set_callback((callback_t)callback);
}

// Forwards to esp_matter's cluster get(), narrowing the ID param to `unsigned int` for Swift interop.
esp_matter::cluster_t *esp_matter::cluster::get_shim(esp_matter::endpoint_t *endpoint, unsigned int cluster_id) {
  return get(endpoint, (uint32_t)cluster_id);
}

// Forwards to esp_matter's attribute get(), narrowing the ID param to `unsigned int` for Swift interop.
esp_matter::attribute_t *esp_matter::attribute::get_shim(esp_matter::cluster_t *cluster, unsigned int attribute_id) {
  return get(cluster, (uint32_t)attribute_id);
}

// If the device currently has no Matter fabric and isn't already advertising,
// opens a 300s basic commissioning window over DNS-SD so it can be re-paired.
void recomissionFabric() {
  if (chip::Server::GetInstance().GetFabricTable().FabricCount() == 0) {
    chip::CommissioningWindowManager & commissionMgr = chip::Server::GetInstance().GetCommissioningWindowManager();
    constexpr auto kTimeoutSeconds = chip::System::Clock::Seconds16(300);
    if (!commissionMgr.IsCommissioningWindowOpen()) {
      commissionMgr.OpenBasicCommissioningWindow(kTimeoutSeconds, chip::CommissioningWindowAdvertisement::kDnssdOnly);
    }
  }
}

// Prints the QR code URL and manual pairing code for BLE-based commissioning.
void printOnboardingCodes() {
  PrintOnboardingCodes(chip::RendezvousInformationFlag::kBLE);
}

// Safely copies `label` into the fixed-size node_label buffer, truncating and NUL-terminating as needed.
void setNodeLabelShim(esp_matter::cluster::basic_information::config_t *config, const char *label) {
  strncpy(config->node_label, label, sizeof(config->node_label) - 1);
  config->node_label[sizeof(config->node_label) - 1] = '\0';
}
