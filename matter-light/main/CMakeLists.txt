# Register the app as an IDF component
# No PRIV_REQUIRES: ESP-IDF auto-detects component requirements by scanning
# MatterInterface.cpp's transitive #includes (via BridgingHeader.h), and
# adding PRIV_REQUIRES explicitly disables that scan entirely rather than
# adding to it -- explicit lists here have repeatedly gone stale/incomplete.
idf_component_register(
    SRCS "../Matter/MatterInterface.cpp"
    PRIV_INCLUDE_DIRS "."
    LDFRAGMENTS "linker.lf"
)

# Clear the default COMPILE_OPTIONS which include a lot of C/C++ specific compiler flags that the Swift compiler will not accept
set_target_properties(${COMPONENT_LIB} PROPERTIES COMPILE_OPTIONS "")

set_property(TARGET ${COMPONENT_LIB} PROPERTY CXX_STANDARD 17)
target_compile_options(${COMPONENT_LIB} PRIVATE "-DCHIP_HAVE_CONFIG_H")

# Compute -Xcc flags to set up the C and C++ header search paths for Swift (for bridging header).
set(SWIFT_INCLUDES)
foreach(dir ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES})
    string(CONCAT SWIFT_INCLUDES ${SWIFT_INCLUDES} "-Xcc ")
    string(CONCAT SWIFT_INCLUDES ${SWIFT_INCLUDES} "-I${dir} ")
endforeach()
foreach(dir ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
    string(CONCAT SWIFT_INCLUDES ${SWIFT_INCLUDES} "-Xcc ")
    string(CONCAT SWIFT_INCLUDES ${SWIFT_INCLUDES} "-I${dir} ")
endforeach()

# Set device-specific march/mabi flags (ESP32-C6 is a single-core RV32IMAC part)
idf_build_get_property(target IDF_TARGET)
if(${target} STREQUAL "esp32c2" OR ${target} STREQUAL "esp32c3")
    set(march_flag "rv32imc_zicsr_zifencei")
    set(mabi_flag "ilp32")
elseif(${target} STREQUAL "esp32p4")
    set(march_flag "rv32imafc_zicsr_zifencei")
    set(mabi_flag "ilp32f")
else()
    set(march_flag "rv32imac_zicsr_zifencei")
    set(mabi_flag "ilp32")
endif()

# Pull the real IDF_VER for this checkout instead of hardcoding a snapshot string;
# some ESP-IDF/Matter headers gate behavior on it.
idf_build_get_property(idf_ver_string IDF_VER)

# Swift compiler flags to build in Embedded Swift mode, optimize for size, choose the right ISA, ABI, C++ language standard, etc.
#
# esp_libc's platform_include shims (sys/reent.h, pthread.h, ...) must be found before
# the toolchain's raw newlib/picolibc headers (which SWIFT_INCLUDES adds below via the
# compiler's own implicit include dirs) -- without this, clang resolves straight to the
# unpatched headers and hits macro/attribute conflicts between newlib and picolibc
# (e.g. _READ_WRITE_RETURN_TYPE undefined, 'noreturn' attribute errors in pthread.h).
# NOTE: this whole block is a SHELL: string passed verbatim to swiftc -- CMake does NOT
# strip '#' comments from inside it, so any comment must stay out here, not inline below.
target_compile_options(${COMPONENT_LIB} PUBLIC "$<$<COMPILE_LANGUAGE:Swift>:SHELL:
        -target riscv32-none-none-eabi
        -Xfrontend -function-sections -enable-experimental-feature Embedded -wmo -parse-as-library -Osize
        -color-diagnostics
        -Xcc -DCHIP_HAVE_CONFIG_H
        -Xcc -std=c++17
        -cxx-interoperability-mode=default
        -Xcc -fno-exceptions
        -Xcc -fno-rtti

        -Xcc -DESP_PLATFORM
        -Xcc -DIDF_VER=\"${idf_ver_string}\"
        -Xcc -DLV_CONF_INCLUDE_SIMPLE
        -Xcc -DMBEDTLS_CONFIG_FILE=\"mbedtls/esp_config.h\"
        -Xcc -DMD5_ENABLED=1
        -Xcc -DSERIAL_FLASHER_BOOT_HOLD_TIME_MS=50
        -Xcc -DSERIAL_FLASHER_RESET_HOLD_TIME_MS=100
        -Xcc -DSOC_MMU_PAGE_SIZE=CONFIG_MMU_PAGE_SIZE
        -Xcc -DSOC_XTAL_FREQ_MHZ=CONFIG_XTAL_FREQ
        -Xcc -DUNITY_INCLUDE_CONFIG_H
        -Xcc -D_GLIBCXX_HAVE_POSIX_SEMAPHORE
        -Xcc -D_GLIBCXX_USE_POSIX_SEMAPHORE
        -Xcc -D_POSIX_READER_WRITER_LOCKS
        -Xcc -march=${march_flag}
        -Xcc -mabi=${mabi_flag}

        -pch-output-dir /tmp
        -Xfrontend -enable-single-module-llvm-emission

        -Xcc -I$ENV{IDF_PATH}/components/esp_libc/platform_include

        ${SWIFT_INCLUDES}

        -import-bridging-header ${CMAKE_CURRENT_LIST_DIR}/BridgingHeader.h
    >")

# Enable Swift support in CMake, force Whole Module builds (required by Embedded Swift), and use "CMAKE_Swift_COMPILER_WORKS" to
# skip the trial compilations which don't (yet) correctly work when cross-compiling.
set(CMAKE_Swift_COMPILER_WORKS YES)
set(CMAKE_Swift_COMPILATION_MODE_DEFAULT wholemodule)
set(CMAKE_Swift_COMPILATION_MODE wholemodule)
enable_language(Swift)

# List of Swift source files to build.
target_sources(${COMPONENT_LIB}
    PRIVATE
    Main.swift
    LED.swift
    RemoteLog.swift
    ../Matter/Attribute.swift
    ../Matter/Clusters.swift
    ../Matter/Matter.swift
    ../Matter/Node.swift
)
