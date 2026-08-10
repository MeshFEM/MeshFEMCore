# Prepare dependencies owned by MeshFEMCore.

if(NOT DEFINED MESHFEMCORE_ROOT)
    get_filename_component(MESHFEMCORE_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
endif()

if(NOT DEFINED MESHFEM_EXTERNAL)
    set(MESHFEM_EXTERNAL "${MESHFEMCORE_ROOT}/3rdparty")
endif()

get_directory_property(hasParent PARENT_DIRECTORY)
if (hasParent)
    set(MESHFEMCORE_ROOT "${MESHFEMCORE_ROOT}" PARENT_SCOPE)
    set(MESHFEM_EXTERNAL "${MESHFEM_EXTERNAL}" PARENT_SCOPE)
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
list(REMOVE_DUPLICATES CMAKE_MODULE_PATH)

include(MeshFEMCoreDownloadExternal)
include(MeshFEMUtils)
include(Warnings)

find_package(Threads REQUIRED) # provides Threads::Threads

if(NOT TARGET Eigen3::Eigen)
    add_library(meshfem_eigen INTERFACE)
    meshfem_download_eigen()
    target_include_directories(meshfem_eigen SYSTEM INTERFACE ${MESHFEM_EXTERNAL}/eigen)
    add_library(Eigen3::Eigen ALIAS meshfem_eigen)
endif()

if(NOT TARGET TBB::tbb)
    set(TBBMALLOC_BUILD ON CACHE BOOL " " FORCE) # needed for CGAL's parallel mesher
    set(TBBMALLOC_PROXY_BUILD OFF CACHE BOOL " " FORCE)
    set(TBB_BUILD_TESTS OFF CACHE BOOL " " FORCE)
    set(TBB_TEST OFF CACHE BOOL " " FORCE)

    meshfem_download_tbb()
    add_subdirectory(${MESHFEM_EXTERNAL}/tbb ${CMAKE_BINARY_DIR}/tbb EXCLUDE_FROM_ALL)

    # Modern oneTBB defines TBB::tbb itself; keep this fallback for older
    # TBB versions that only define the concrete tbb/tbbmalloc targets.
    if(NOT TARGET TBB::tbb)
        add_library(tbb_tbb INTERFACE)
        target_link_libraries(tbb_tbb INTERFACE tbbmalloc tbb)
        add_library(TBB::tbb ALIAS tbb_tbb)
    endif()

    # oneTBB headers can trigger a large volume of warnings, some of which
    # can be treated as errors by other libraries. We suppress those warnings
    # by patching the relevant library targets to mark their headers as SYSTEM.
    meshfem_target_hide_warnings(tbb tbbmalloc)
endif()
