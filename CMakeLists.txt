cmake_minimum_required(VERSION 3.14...3.31)
project(MeshFEMCore LANGUAGES CXX)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(MESHFEMCORE_TOPLEVEL_PROJECT ON)
else()
    set(MESHFEMCORE_TOPLEVEL_PROJECT OFF)
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
list(REMOVE_DUPLICATES CMAKE_MODULE_PATH)

option(MESHFEM_NATIVE                "Add march=native flag to encourage generation of SIMD instructions. WARNING: this option will propagate to code linking against MeshFEM"   ON)
option(MESHFEM_FAST_MATH             "Add ffast-math   flag to encourage generation of SIMD instructions. WARNING: this option will propagate to code linking against MeshFEM"   OFF)
option(MESHFEM_ADDRESS_SANITIZER     "Whether to use address sanitizer in Debug mode" OFF)
option(MESHFEM_ENABLE_BENCHMARKING   "Enable the benchmarking code" ON)
option(MESHFEMCORE_BUILD_TESTS "Build MeshFEMCore tests" ${MESHFEMCORE_TOPLEVEL_PROJECT})

option(MESHFEM_DISABLE_CXX11_ABI_GCC "Don't use GCC's new C++11 ABI; needed to prevent linker errors with libraries compiled with the old ABI" OFF)

include(MeshFEMCoreDependencies)

add_library(MeshFEMCore STATIC
    src/lib/MeshFEMCore/Parallelism.cc
    src/lib/MeshFEMCore/GlobalBenchmark.cc
)

# Keep the existing export macro available when MeshFEMCore is built without
# the outer MeshFEM shared library.
meshfem_generate_export_header(MeshFEMCore
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
meshfem_apply_abi_flags(MeshFEMCore)

if(MESHFEM_NATIVE)
    CHECK_CXX_COMPILER_FLAG(-march=native COMPILER_SUPPORTS_MARCH_NATIVE)
    if(COMPILER_SUPPORTS_MARCH_NATIVE)
        target_compile_options(${PROJECT_NAME} PUBLIC -march=native)
    else()
        CHECK_CXX_COMPILER_FLAG(-mcpu=native COMPILER_SUPPORTS_MCPU_NATIVE)
        if(COMPILER_SUPPORTS_MCPU_NATIVE)
            target_compile_options(${PROJECT_NAME} PUBLIC -mcpu=native)
        else()
            message(WARNING "The compiler ${CMAKE_CXX_COMPILER} does not support -march=native or -mcpu=native. The option MESHFEM_NATIVE will be ignored.")
        endif()
    endif()
endif()

if(MESHFEM_FAST_MATH)
    target_compile_options(${PROJECT_NAME} PUBLIC -ffast-math)
endif()

if(MESHFEM_DISABLE_CXX11_ABI_GCC)
    target_compile_definitions(MeshFEMCore PUBLIC -D_GLIBCXX_USE_CXX11_ABI=0)
endif()

if (MESHFEM_ENABLE_BENCHMARKING)
    target_compile_definitions(MeshFEMCore PUBLIC -DBENCHMARK)
endif()
