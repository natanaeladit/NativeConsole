using Interop = NativeConsole.Interop.Interop;

Console.WriteLine("Hello .NET calling native code via SWIG.");

const int a = 11;
const int b = 12;
var c = Interop.add(a, b);
Console.WriteLine($"{a} + {b} = {c}");

const int d = 22;
const int e = 33;
var f = Interop.add(d, e);
Console.WriteLine($"{d} + {e} = {f}");

const int g = 44;
const int h = 55;
var i = Interop.add(g, h);
Console.WriteLine($"{g} + {h} = {i}");

Console.WriteLine("Done.");
