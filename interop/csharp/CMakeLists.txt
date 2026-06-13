# interop/csharp/CMakeLists.txt : Compile the SWIG-generated C# sources into
# a .NET 10 managed assembly (NativeConsole.Interop.dll) via `dotnet build`.
# The assembly name must differ from the native glue library (Interop.dll):
# both land in the same output directory, and the SWIG-generated
# [DllImport("Interop")] must keep resolving to the native DLL.
#
# Expects from the parent scope (interop/CMakeLists.txt):
#   INTEROP_CSHARP_DIR        - directory holding the generated .cs files;
#                               the .csproj is written here too
#   INTEROP_DOTNET_OUTPUT_DIR - where the managed assembly is placed (next to
#                               the native glue library)
#   DOTNET_EXECUTABLE         - located by find_program() in the top-level
#                               CMakeLists

# Path of the project file driving the managed build; placed in the same
# directory as the generated sources so the SDK can glob them.
set(INTEROP_CSPROJ ${INTEROP_CSHARP_DIR}/Interop.csproj)

# Platform-specific names of the native libraries the wrapper needs at
# runtime: the SWIG glue (target Interop) and the wrapped library (Utils).
if(WIN32)
    set(INTEROP_NATIVE_GLUE_LIB  ${INTEROP_DOTNET_OUTPUT_DIR}/Interop.dll)
    set(INTEROP_NATIVE_UTILS_LIB ${CMAKE_BINARY_DIR}/lib/Utils.dll)
else()
    set(INTEROP_NATIVE_GLUE_LIB  ${INTEROP_DOTNET_OUTPUT_DIR}/libInterop.so)
    set(INTEROP_NATIVE_UTILS_LIB ${CMAKE_BINARY_DIR}/lib/libUtils.so)
endif()

# Write the SDK-style project at configure time.
#
# - The SWIG sources are listed as an explicit Compile glob, NOT via the
#   SDK's default items: the build below outputs (-o) to the parent of this
#   project directory, which makes the SDK's DefaultItemExcludes
#   ($(OutputPath)/**) swallow every default-globbed .cs in the project and
#   silently produce an empty assembly. Explicit Compile items are not
#   subject to DefaultItemExcludes.
# - The native libraries are None items with CopyToOutputDirectory so they
#   travel to the output of ANY project that references this one
#   (MSBuild propagates copy-to-output items across ProjectReferences).
file(WRITE ${INTEROP_CSPROJ}
"<Project Sdk=\"Microsoft.NET.Sdk\">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <AssemblyName>NativeConsole.Interop</AssemblyName>
    <RootNamespace>NativeConsole.Interop</RootNamespace>
    <Nullable>disable</Nullable>
    <AllowUnsafeBlocks>true</AllowUnsafeBlocks>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include=\"swig/**/*.cs\" />
  </ItemGroup>
  <ItemGroup>
    <None Include=\"${INTEROP_NATIVE_GLUE_LIB}\" CopyToOutputDirectory=\"PreserveNewest\" Condition=\"Exists('${INTEROP_NATIVE_GLUE_LIB}')\" />
    <None Include=\"${INTEROP_NATIVE_UTILS_LIB}\" CopyToOutputDirectory=\"PreserveNewest\" Condition=\"Exists('${INTEROP_NATIVE_UTILS_LIB}')\" />
  </ItemGroup>
</Project>
")

# Build the managed assembly on every build (ALL).
#   -c      : map the CMake configuration onto the dotnet configuration
#   -o      : drop the assembly next to the native glue library
# DEPENDS Interop orders this after the native target, which itself runs
# after SWIG has generated the C# sources this build consumes.
add_custom_target(interop_dotnet ALL
    COMMAND ${DOTNET_EXECUTABLE} build "${INTEROP_CSPROJ}"
            -c $<IF:$<CONFIG:Debug>,Debug,Release>
            -o "${INTEROP_DOTNET_OUTPUT_DIR}"
    DEPENDS Interop
    WORKING_DIRECTORY ${INTEROP_CSHARP_DIR}
    COMMENT "Building .NET 10 interop assembly from SWIG-generated C# sources"
    VERBATIM)
