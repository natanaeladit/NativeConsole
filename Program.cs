using Interop = NativeConsole.Interop.Interop;

Console.WriteLine("Hello .NET calling native code via SWIG.");

const int a = 11;
const int b = 12;
var c = Interop.add(a, b);
Console.WriteLine($"{a} + {b} = {c}");

Console.WriteLine("Done.");
