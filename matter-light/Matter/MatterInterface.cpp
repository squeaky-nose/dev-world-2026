#include "BridgingHeader.h"
#include <setup_payload/OnboardingCodesUtil.h>
#include <cstring>

esp_err_t esp_matter::attribute::set_callback_shim(callback_t_shim callback) {
  return set_callback((callback_t)callback);
}

esp_matter::cluster_t *esp_matter::cluster::get_shim(esp_matter::endpoint_t *endpoint, unsigned int cluster_id) {
  return get(endpoint, (uint32_t)cluster_id);
}

esp_matter::attribute_t *esp_matter::attribute::get_shim(esp_matter::cluster_t *cluster, unsigned int attribute_id) {
  return get(cluster, (uint32_t)attribute_id);
}

void recomissionFabric() {
  if (chip::Server::GetInstance().GetFabricTable().FabricCount() == 0) {
    chip::CommissioningWindowManager & commissionMgr = chip::Server::GetInstance().GetCommissioningWindowManager();
    constexpr auto kTimeoutSeconds = chip::System::Clock::Seconds16(300);
    if (!commissionMgr.IsCommissioningWindowOpen()) {
      commissionMgr.OpenBasicCommissioningWindow(kTimeoutSeconds, chip::CommissioningWindowAdvertisement::kDnssdOnly);
    }
  }
}

void printOnboardingCodes() {
  PrintOnboardingCodes(chip::RendezvousInformationFlag::kBLE);
}

void setNodeLabelShim(esp_matter::cluster::basic_information::config_t *config, const char *label) {
  strncpy(config->node_label, label, sizeof(config->node_label) - 1);
  config->node_label[sizeof(config->node_label) - 1] = '\0';
}
