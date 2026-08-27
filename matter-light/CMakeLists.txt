#
#  CMakeLists.txt
#  matter-light
#
#  Created by Sushant Verma on 27/8/2026 for [/dev/world 2026](https://devworld.au/)
#

# The following lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.29)

if(NOT DEFINED ENV{ESP_MATTER_PATH})
    message(FATAL_ERROR "Please set ESP_MATTER_PATH to the path of esp-matter repo")
endif(NOT DEFINED ENV{ESP_MATTER_PATH})

if(NOT DEFINED ENV{ESP_MATTER_DEVICE_PATH})
    if("${IDF_TARGET}" STREQUAL "esp32c6")
        # Seeed XIAO ESP32C6: onboard LED on GPIO15, unlike Espressif's DevKitC/M
        # boards (GPIO8). See device_hal/device/xiao_esp32c6/device.c.
        set(ENV{ESP_MATTER_DEVICE_PATH} $ENV{ESP_MATTER_PATH}/device_hal/device/xiao_esp32c6)
    else()
        message(FATAL_ERROR "Unsupported IDF_TARGET (this project targets esp32c6)")
    endif()
endif(NOT DEFINED ENV{ESP_MATTER_DEVICE_PATH})

set(PROJECT_VER "1.0")
set(PROJECT_VER_NUMBER 1)

set(ESP_MATTER_PATH $ENV{ESP_MATTER_PATH})
set(MATTER_SDK_PATH ${ESP_MATTER_PATH}/connectedhomeip/connectedhomeip)

# This should be done before using the IDF_TARGET variable.
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
include($ENV{ESP_MATTER_DEVICE_PATH}/esp_matter_device.cmake)

set(EXTRA_COMPONENT_DIRS
    "${ESP_MATTER_PATH}/examples/common"
    "${MATTER_SDK_PATH}/config/esp32/components"
    "${ESP_MATTER_PATH}/components"
    "${ESP_MATTER_PATH}/device_hal/device"
    ${extra_components_dirs_append})

project(matter_light)

# Device identity strings shown to Matter controllers (Basic Information cluster)
# are set as defaults directly in connectedhomeip's CHIPDeviceConfig.h -- passing
# multi-word -D string values through here breaks: esp-matter's CMake->GN args.gn
# serialization splits on raw spaces inside the quoted value, mangling the string.
idf_build_set_property(CXX_COMPILE_OPTIONS "-std=gnu++17;-Os;-DCHIP_HAVE_CONFIG_H;-DCHIP_DEVICE_CONFIG_ENABLE_COMMISSIONABLE_DEVICE_NAME=1" APPEND)
idf_build_set_property(C_COMPILE_OPTIONS "-Os" APPEND)
# For RISCV chips, project_include.cmake sets -Wno-format, but does not clear various
# flags that depend on -Wformat
idf_build_set_property(COMPILE_OPTIONS "-Wno-format-nonliteral;-Wno-format-security" APPEND)
