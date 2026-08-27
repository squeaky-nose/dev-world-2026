//
//  BridgingHeader.h
//  matter-light
//
//  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
//

// C standard library
// ==================

// sys/types.h must come first: it defines ssize_t, which esp_libc's stdio.h shim
// (platform_include/stdio.h, used for picolibc/newlib compatibility) requires but
// doesn't itself pull in -- normally already visible by the time a C file reaches
// stdio.h via some other header, but this is the very first include here.
#include <sys/types.h>
#include <stdio.h>
#include <math.h>

// ESP IDF
// =======

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <driver/gpio.h>
#include <sdkconfig.h>
#include <nvs_flash.h>
#include <esp_http_client.h>
#include <esp_timer.h>
#include <esp_err.h>
#include "cJSON.h"

// esp_crt_bundle.h pulls in mbedtls's build_info.h, which fails to parse
// during the Swift bridging-header PCH generation pass specifically (a
// separate compile from MatterInterface.cpp's normal C++ compile, with a
// different flag set -- #include MBEDTLS_CONFIG_FILE doesn't expand to a
// valid header-name token there). We don't need any mbedtls types though:
// esp_http_client_config_t.crt_bundle_attach is just `esp_err_t (*)(void*)`,
// so declare the one function directly instead of including the header.
// Attaches the default TLS certificate bundle to an esp_http_client config (used for HTTPS remote-log requests).
extern "C" esp_err_t esp_crt_bundle_attach(void *conf);

// ESP Matter
// ==========

#define CHIP_HAVE_CONFIG_H 1
#define CHIP_USE_ENUM_CLASS_FOR_IM_ENUM 1
#define CHIP_ADDRESS_RESOLVE_IMPL_INCLUDE_HEADER <lib/address_resolve/AddressResolve_DefaultImpl.h>

// There seems to be assumption in FabricTable.h that strnlen is implicitly available via some other headers, but that
// turns out to not be the case when importing these headers in Swift. Let's manually declare strnlen as a workaround.
//
// connectedhomeip/src/credentials/FabricTable.h:82:69: error: use of undeclared identifier 'strnlen'
// Manual declaration of the standard strnlen(), otherwise unavailable to FabricTable.h in this build.
extern "C" size_t strnlen(const char *s, size_t maxlen);
// esp-matter/components/esp_matter/esp_matter_client.h:57:26: error: use of undeclared identifier 'strdup'
// Manual declaration of the standard strdup(), otherwise unavailable to esp_matter_client.h in this build.
extern "C" char *strdup(const char *s1);

#include <esp_matter.h>
#include <esp_matter_cluster.h>
#include <app-common/zap-generated/ids/Clusters.h>
#include <app/server/Server.h>

// Swift Matter interface
// ======================

#include "../Matter/MatterInterface.h"
