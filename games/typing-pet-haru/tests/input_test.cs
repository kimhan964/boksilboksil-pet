using System;
using System.Reflection;
using System.Runtime.InteropServices;
internal static class TypingInputTest {
    private static void Main(string[] args) {
        Type type=Assembly.LoadFile(System.IO.Path.GetFullPath(args[0])).GetType("TypingInput");
        MethodInfo callback=type.GetMethod("OnKey",BindingFlags.NonPublic|BindingFlags.Static);
        FieldInfo count=type.GetField("presses",BindingFlags.NonPublic|BindingFlags.Static);
        IntPtr data=Marshal.AllocHGlobal(24);
        Action<int,int> key=delegate(int vk,int message) {
            Marshal.WriteInt32(data,vk);
            callback.Invoke(null,new object[]{0,new IntPtr(message),data});
        };
        try {
            key(65,0x100); key(65,0x100); key(65,0x100);
            if ((long)count.GetValue(null)!=1) throw new Exception("Auto-repeat counted more than once");
            key(65,0x101); key(65,0x100); key(65,0x101);
            if ((long)count.GetValue(null)!=2) throw new Exception("Distinct press was lost");
            key(16,0x100); key(160,0x100); key(18,0x104);
            if ((long)count.GetValue(null)!=2) throw new Exception("Modifier-only press should not animate");
            for(int i=0;i<100;i++) { key(66,0x100); key(66,0x101); }
            if ((long)count.GetValue(null)!=102) throw new Exception("Burst presses were lost");
            MethodInfo mouse=type.GetMethod("OnMouse",BindingFlags.NonPublic|BindingFlags.Static);
            foreach(int message in new int[]{0x200,0x202,0x205,0x208,0x20C,0x20A,0x20E})
                mouse.Invoke(null,new object[]{0,new IntPtr(message),data});
            if ((long)count.GetValue(null)!=102) throw new Exception("Mouse movement/release/wheel should not count");
            foreach(int message in new int[]{0x201,0x204,0x207,0x20B})
                mouse.Invoke(null,new object[]{0,new IntPtr(message),data});
            mouse.Invoke(null,new object[]{-1,new IntPtr(0x201),data});
            if ((long)count.GetValue(null)!=106) throw new Exception("Mouse button count mismatch");
            Console.WriteLine("TYPING_CALLBACK_PASS: repeat, release, modifiers, 100 presses, 4 mouse buttons, non-click exclusion");
        } finally { Marshal.FreeHGlobal(data); }
    }
}
