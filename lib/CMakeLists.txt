SET(LIBUTILS_SRC utils.cpp)
ADD_DEFINITIONS(-DCPLUSPLUS)
ADD_LIBRARY(Utils SHARED ${LIBUTILS_SRC})

# utils.h has no __declspec(dllexport) annotations; without this MSVC emits no
# import library (Utils.lib) and targets linking Utils fail on Windows.
set_property(TARGET Utils PROPERTY WINDOWS_EXPORT_ALL_SYMBOLS TRUE)