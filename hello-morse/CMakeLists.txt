#
#  CMakeLists.txt
#  hello-morse
#
#  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
#

cmake_minimum_required(VERSION 3.29)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
# Skip configuring components this project doesn't use, to keep the build fast.
idf_build_set_property(MINIMAL_BUILD ON)
project(main)
