# Prints the friendly name of the Windows default audio CAPTURE device.
# Used by the whisper hotkey setup to discover the exact device name that
# ffmpeg's dshow input expects.
#
# Notes:
#   - WAVE_MAPPER / winmm returns "Microsoft Sound Mapper", not the real name —
#     that's why we go straight to the Core Audio IMMDeviceEnumerator.
#   - The IMMDeviceEnumerator interface GUID (A95664D2-...) is NOT the same as
#     the MMDeviceEnumerator coclass GUID (BCDE0395-...). Using the coclass
#     GUID for the interface causes E_NOINTERFACE on cast.

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
[ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMDE { void N(); [PreserveSig] int G(int a, int b, out IMD d); }
[ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMD { void N1(); [PreserveSig] int O(int a, out IPS s); void N2(); void N3(); }
[ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IPS { void N1(); void N2(); [PreserveSig] int G(ref PK k, out PV v); void N3(); void N4(); }
[StructLayout(LayoutKind.Sequential)] public struct PK { public Guid f; public int p; }
[StructLayout(LayoutKind.Explicit)] public struct PV { [FieldOffset(0)] public short vt; [FieldOffset(8)] public IntPtr p; }
public class CA {
    public static string N() {
        var t = Type.GetTypeFromCLSID(new Guid("BCDE0395-E52F-467C-8E3D-C4579291692E"));
        var e = (IMDE)Activator.CreateInstance(t);
        IMD d; e.G(1, 0, out d);                                // eCapture=1, eConsole=0
        IPS s; d.O(0, out s);                                   // STGM_READ=0
        var k = new PK { f = new Guid("A45C254E-DF1C-4EFD-8020-67D146A850E0"), p = 14 }; // PKEY_Device_FriendlyName
        PV v; s.G(ref k, out v);
        return v.vt == 31 ? Marshal.PtrToStringUni(v.p) : null;  // VT_LPWSTR=31
    }
}
'@
[CA]::N()
