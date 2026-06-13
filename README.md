## What this is

A minimal demo showing how a **.NET 10 C# app calls into a native C++ library through a SWIG-generated interop layer**, all orchestrated by CMake. The wrapped functionality is a single `add(int, int)` function in `lib/`.

## Build

CMake-presets driven (Ninja + MSVC `cl.exe` on Windows). `swig`, the .NET 10 SDK, and `cmake` must be on PATH. On a fresh Linux box, `setup.sh` installs all prerequisites (apt).

```sh
cmake --preset x64-debug          # configure (also: x64-release, linux-debug)
cmake --build out/build/x64-debug # build everything
```

Build outputs land in `out/build/<preset>/`. The managed app ends up in `out/build/<preset>/managed/`.

Run the artifacts:
- Native C++ exe: `out/build/<preset>/NativeConsole(.exe)`
- Managed app: `dotnet out/build/<preset>/managed/ManagedConsole.dll`

## Architecture / build graph

Two independent programs are built from the same `lib/`:

1. **`NativeConsole`** — pure C++ exe (`console.cpp` + `lib/utils.cpp`), compiled directly. No interop involved.
2. **`ManagedConsole`** — .NET 10 console app (`Program.cs`) that reaches the same C++ `add()` through the SWIG chain below.

The interop chain (each step is a CMake target depending on the previous):

```
lib/  ──> Utils (shared C++ lib)
interop/interop.i + lib/utils.h
   ──[swig -csharp -c++]──> generated C++ glue + C# bindings   (target: interop_swig)
   ──> Interop (native glue shared lib, links Utils)           (target: Interop)
   ──[dotnet build]──> NativeConsole.Interop.dll (managed)     (target: interop_dotnet)
ManagedConsole.csproj ──ProjectReference──> generated Interop.csproj
   ──[dotnet build, target: managed_console]──> ManagedConsole app
```

`ManagedConsole.csproj` does not reference any source under `out/` directly — it references the **generated** `interop/csharp/Interop.csproj` living in the CMake build tree, located via the `NativeBuildDir` MSBuild property (defaulted in the csproj, overridden per-preset by the `managed_console` CMake target).

## Debugging the native C++ layer on WSL

You can run the managed `ManagedConsole` app on WSL and set breakpoints in the **native C++** code (`lib/utils.cpp`, the generated SWIG glue) using **gdb**. This is native-only debugging: gdb treats the .NET host as an ordinary process and binds breakpoints in `libUtils.so`/`libInterop.so` when they load. Managed (C#) frames are not debuggable this way — mixed-mode debugging is Windows-only.

How it works here:
- `lib/CMakeLists.txt`'s `Utils` and `interop`'s `Interop` build with debug info under the `linux-debug` preset (`CMAKE_BUILD_TYPE=Debug`), so the `.so` files carry symbols.
- The managed build emits a native **apphost** executable (`ManagedConsole`, no extension) next to its dll, with `libInterop.so`/`libUtils.so` copied alongside it. Launching that apphost loads the runtime in-process, so gdb stays attached to the process that runs the C++.

In Visual Studio (active target = WSL):
1. Build All so the `managed_console` chain is up to date.
2. One-time: `cp .gdbinit ~/.gdbinit` in WSL (CLR signal pass-through + pending breakpoints; gdb only auto-loads `.gdbinit` from `$HOME`, not the repo).
3. Select the **"Native C++ (WSL gdb) - ManagedConsole"** startup item (defined in `.vs/launch.vs.json`), set breakpoints in `lib/utils.cpp`, and press F5. Execution stops in `add()`.

`.vs/launch.vs.json` uses `type: cppgdb` and launches `program` = the apphost with `cwd` set to its directory so the native libs resolve. The path must be the **WSL (Linux) path**, because gdb runs on WSL.

Command-line fallback (no VS), from a WSL shell after building:
```sh
cd ~/.vs/NativeConsole/out/build/linux-debug/managed   # remote build root (per linux-debug preset)
gdb --args ./ManagedConsole      # or: gdb --args dotnet ManagedConsole.dll
(gdb) break add
(gdb) run
```

## Editing the wrapped surface

To expose more native API to C#: add declarations to `lib/utils.h` (and definitions in `lib/utils.cpp`), then ensure they're wrapped via `interop/interop.i` (`%include "../lib/utils.h"` already pulls in everything in that header). SWIG re-runs automatically because the custom command `DEPENDS` on `interop.i` and `lib/utils.h`.
