# CMakeList.txt : CMake project for NativeConsole, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.10)

find_program(DOTNET_EXECUTABLE dotnet REQUIRED)

# Enable Hot Reload for MSVC compilers if supported.
if (POLICY CMP0141)
  cmake_policy(SET CMP0141 NEW)
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

project ("NativeConsole")
ADD_SUBDIRECTORY(lib)
ADD_SUBDIRECTORY(interop)

# Add source to this project's executable.
add_executable (NativeConsole "console.cpp" "console.h" "lib/utils.cpp" "lib/utils.h")

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET NativeConsole PROPERTY CXX_STANDARD 20)
endif()

# Managed demo app: calls native add() through the SWIG interop layer.
#   -p:NativeBuildDir points the csproj at this build tree for the wrapper
#   assembly and native DLLs; -o keeps the app out of the source tree.
add_custom_target(managed_console ALL
    COMMAND ${DOTNET_EXECUTABLE} build "${CMAKE_CURRENT_SOURCE_DIR}/ManagedConsole.csproj"
            -c $<IF:$<CONFIG:Debug>,Debug,Release>
            -p:NativeBuildDir=${CMAKE_BINARY_DIR}
            -o "${CMAKE_BINARY_DIR}/managed"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building ManagedConsole .NET 10 console app"
    VERBATIM)

# The app consumes the wrapper assembly and the native DLLs, so build the
# whole interop chain (swig -> Interop -> interop_dotnet) first.
add_dependencies(managed_console interop_dotnet)

# TODO: Add tests and install targets if needed.
