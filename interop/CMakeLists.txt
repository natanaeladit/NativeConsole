# interop/CMakeLists.txt : Generate a .NET 10 C# wrapper for the `utils`
# library by invoking the `swig` executable manually and compile the native
# glue into a shared library. The SWIG-generated C# sources are compiled into
# a managed assembly by csharp/CMakeLists.txt.

# Locate the swig executable directly (no find_package/UseSWIG module);
# REQUIRED makes configuration fail fast if swig is not installed.
find_program(SWIG_EXECUTABLE swig REQUIRED)

# ---------------------------------------------------------------------------
# 1. swig -> generate the native wrapper (.cpp) + C# (.cs) binding sources
# ---------------------------------------------------------------------------

# The SWIG interface definition: declares what to wrap (utils.h) and how.
set(INTEROP_INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/interop.i)

# Location of the wrapped library's headers (utils.h lives here).
set(INTEROP_LIB_DIR   ${CMAKE_CURRENT_SOURCE_DIR}/../lib)

# Where SWIG drops the generated .cs files; also where csharp/CMakeLists.txt
# writes the Interop.csproj that compiles them.
set(INTEROP_CSHARP_DIR ${CMAKE_CURRENT_BINARY_DIR}/csharp)

# Where SWIG drops the generated C++ glue source.
set(INTEROP_CPP_DIR ${CMAKE_CURRENT_BINARY_DIR}/cpp)

# SWIG does not create output directories itself; create them at configure
# time so the custom command below cannot fail on a missing path.
file(MAKE_DIRECTORY ${INTEROP_CSHARP_DIR}/swig)
file(MAKE_DIRECTORY ${INTEROP_CPP_DIR})

# Full path of the native glue source SWIG will emit; doubles as the OUTPUT
# that hooks the custom command into the dependency graph.
set(INTEROP_WRAP_CPP ${INTEROP_CPP_DIR}/swig/interop.cpp)

# Run swig at build time to produce the C++ wrapper and the C# binding sources.
#   -csharp    : target language is C#
#   -c++       : interop.i wraps C++ (std::vector/std::string + utils.h)
#   -namespace : C# namespace for the generated types
#   -outdir    : directory for the generated .cs files
#   -I         : header search path so utils.h resolves from interop.i
#   -o         : path of the generated C++ wrapper source
# DEPENDS re-runs SWIG whenever the interface or the wrapped header changes;
# VERBATIM guarantees the arguments are passed to swig unmangled.
add_custom_command(
    OUTPUT ${INTEROP_WRAP_CPP}
    COMMAND ${SWIG_EXECUTABLE}
            -csharp -c++
            -namespace NativeConsole.Interop
            -outdir ${INTEROP_CSHARP_DIR}/swig
            -I${INTEROP_LIB_DIR}
            -o ${INTEROP_WRAP_CPP}
            ${INTEROP_INTERFACE}
    DEPENDS ${INTEROP_INTERFACE} ${INTEROP_LIB_DIR}/utils.h
    COMMENT "Running SWIG to generate C# interop wrapper for utils"
    VERBATIM)

# Wrap the generated file in a named target so other targets can depend on
# "SWIG has run" without referencing the file path directly.
add_custom_target(interop_swig DEPENDS ${INTEROP_WRAP_CPP})

# ---------------------------------------------------------------------------
# 2. Compile the SWIG-generated glue into the native shared library:
#    produces (lib)Interop(.so|.dll), loaded by the C# via [DllImport].
# ---------------------------------------------------------------------------

# Build the glue source as a shared library so the .NET runtime can P/Invoke
# into it at runtime.
add_library(Interop SHARED ${INTEROP_WRAP_CPP})

# Ensure SWIG generates the source before this target tries to compile it.
add_dependencies(Interop interop_swig)

# The generated wrapper and utils.h are compiled as C++20.
set_property(TARGET Interop PROPERTY CXX_STANDARD 20)

# The wrapper calls into add()/utils, so link the shared utils library...
target_link_libraries(Interop PRIVATE Utils)

# ...and let the wrapper's #include "utils.h" resolve at compile time.
target_include_directories(Interop PRIVATE ${INTEROP_LIB_DIR})

# ---------------------------------------------------------------------------
# 3. dotnet -> compile the SWIG-generated C# into a .NET 10 assembly
#    (handled by csharp/CMakeLists.txt)
# ---------------------------------------------------------------------------

# Keep the managed assembly next to the native glue library so both are
# found together at runtime.
set(INTEROP_DOTNET_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})

# Hand off to the dedicated C# build; it consumes INTEROP_CSHARP_DIR and
# INTEROP_DOTNET_OUTPUT_DIR from this scope.
add_subdirectory(csharp)
