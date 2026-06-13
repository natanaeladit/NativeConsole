%module Interop

%{
    // This block is copied verbatim into the generated _wrap.cxx
    // — it's what makes the wrapper compile
    #include "../lib/utils.h"
%}

// This tells SWIG to parse the header and generate bindings for everything in it
%include "../lib/utils.h"