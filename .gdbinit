# gdb settings for debugging the native C++ layer inside the .NET-hosted
# ManagedConsole process on Linux/WSL. Copy this to your WSL home once:
#
#     cp .gdbinit ~/.gdbinit
#
# (gdb auto-loads ~/.gdbinit but, for security, NOT a .gdbinit from the
# current directory, so it must live in your home directory.)

# The CLR raises SIGSEGV as part of normal operation (managed null-checks,
# hardware-exception handling). Pass it through to the runtime instead of
# halting gdb on every occurrence. If gdb still stops on other runtime
# signals during startup, add matching `handle SIG## nostop noprint pass`
# lines (the realtime signals SIG33-SIG36 are used for GC/thread suspension).
handle SIGSEGV nostop noprint pass

# libUtils.so / libInterop.so are loaded lazily on the first P/Invoke, so a
# breakpoint in utils.cpp is unresolved at launch. Bind it once the .so loads.
set breakpoint pending on
