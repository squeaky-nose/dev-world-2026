//
//  BridgingHeader.h
//  hello-morse
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

#pragma once

#include <stdio.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "sdkconfig.h"

// Thin wrappers around the ESP_LOGx macros. The macros themselves can't be
// called from Swift (they're variadic and expand using fixed format
// strings), so these take an already-formatted message and forward it
// through "%s", letting ESP-IDF still handle level filtering, colorization,
// and the timestamp/tag prefix as usual.
/// Logs `message` under `tag` at verbose level.
static inline void swift_log_verbose(const char *tag, const char *message) {
  ESP_LOGV(tag, "%s", message);
}
/// Logs `message` under `tag` at debug level.
static inline void swift_log_debug(const char *tag, const char *message) {
  ESP_LOGD(tag, "%s", message);
}
/// Logs `message` under `tag` at info level.
static inline void swift_log_info(const char *tag, const char *message) {
  ESP_LOGI(tag, "%s", message);
}
/// Logs `message` under `tag` at warning level.
static inline void swift_log_warn(const char *tag, const char *message) {
  ESP_LOGW(tag, "%s", message);
}
/// Logs `message` under `tag` at error level.
static inline void swift_log_error(const char *tag, const char *message) {
  ESP_LOGE(tag, "%s", message);
}
