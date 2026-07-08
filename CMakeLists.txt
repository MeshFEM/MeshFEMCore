cmake_minimum_required(VERSION 3.14...3.31)
project(MeshFEMCore LANGUAGES CXX)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(MESHFEMCORE_TOPLEVEL_PROJECT ON)
else()
    set(MESHFEMCORE_TOPLEVEL_PROJECT OFF)
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
list(REMOVE_DUPLICATES CMAKE_MODULE_PATH)

option(MESHFEMCORE_BUILD_TESTS "Build MeshFEMCore tests" ${MESHFEMCORE_TOPLEVEL_PROJECT})

include(MeshFEMCoreDependencies)

add_library(MeshFEMCore STATIC
    src/lib/MeshFEMCore/Types.cc
    src/lib/MeshFEMCore/Parallelism.cc
    src/lib/MeshFEMCore/GlobalBenchmark.cc
)

# Keep the existing export macro available when MeshFEMCore is built without
# the outer MeshFEM shared library.
include(GenerateExportHeader)
generate_export_header(MeshFEMCore
    BASE_NAME MeshFEM
    EXPORT_FILE_NAME ${CMAKE_BINARY_DIR}/exports/MeshFEM_export.h
)

target_include_directories(MeshFEMCore PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/lib>
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/exports>
)
target_compile_features(MeshFEMCore PUBLIC cxx_std_17)

target_link_libraries(MeshFEMCore
    PUBLIC
        TBB::tbb
        Threads::Threads
        Eigen3::Eigen
    PRIVATE
        warnings::all
)

target_compile_definitions(MeshFEMCore PUBLIC -DMESHFEM_WITH_TBB -DNOMINMAX -D_ENABLE_EXTENDED_ALIGNED_STORAGE -D_USE_MATH_DEFINES)
target_compile_options(MeshFEMCore PUBLIC -fvisibility=hidden)

if(MESHFEM_DISABLE_CXX11_ABI_GCC)
    target_compile_definitions(MeshFEMCore PUBLIC -D_GLIBCXX_USE_CXX11_ABI=0)
endif()

if(MESHFEM_ENABLE_BENCHMARKING)
    target_compile_definitions(MeshFEMCore PUBLIC -DBENCHMARK)
endif()
