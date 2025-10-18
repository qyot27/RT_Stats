// ----------------------------------------------------------------
//	Compiling for Avisynth v2.58 & v2.60/x86, v2.60/x64, under VS2008
//
// For AVS+, also need additional Avisynth+ headers somewhere in an AVS directory, (Get latest from Pinterf avs+ source)
//
// AVS
//   alignment.h
//   avisynth.h   // ALSO Need This one in Current Src directory
//   capi.h
//   config.h
//   cpuid.h
//   minmax.h
//   types.h
//   win.h
//
// Point Menu/Tools/Options/Projects and Solutions/VC Directories/ :Include Files: Win32 and x64, to the AVS Parent.
//
// For x64, add '_WIN64' to Preprocessor Definitions (for both C++/Preprocessor & Resources/General).
//        (Do NOT delete any 'WIN32' entry).
// For Avs v2.5, Add 'AVISYNTH_PLUGIN_25' to Preprocessor Definitions (for both C++/Preprocessor & Resources/General).
//   Avs v2.5 includes AVISYNTH_INTERFACE_VERSION=3 as avisynth25.h
//   Avs+ v2.6/x86/x64 includes AVISYNTH_INTERFACE_VERSION=6 as avisynth.h
// ----------------------------------------------------------------

To Build in VS 2008, (See Above AVS Header stuff, need be set up, other additions already configured).

Click on 'RT_Stats.sln',
In 'Build Menu', Click 'Batch Build'.
Click 'ReBuild'.

Result dll's will be in
    Release\,
        RT_Stats_25.dll        // Avs 2.58 dll
        RT_Stats_x86.dll       // Avs+ 2.6 x86 dll.
    x64\Release\
        RT_Stats_x64.dll       // Avs+ 2.6 x64 dll.
