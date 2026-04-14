// Frida script: Log File.exists checks for common root/emulator indicators.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-file-exists.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-file-exists.js

var WATCH_PATTERNS = [
    "su",
    "magisk",
    "busybox",
    "goldfish",
    "qemu",
    "test-keys",
    "xposed",
    "frida",
];

Java.perform(function () {
    var File = Java.use("java.io.File");
    var originalExists = File.exists.overload();

    originalExists.implementation = function () {
        var path = "";
        var result;

        try {
            path = this.getAbsolutePath();
        } catch (error) {
            path = "<unknown>";
        }

        result = originalExists.call(this);

        if (WATCH_PATTERNS.some(function (pattern) { return path.toLowerCase().indexOf(pattern) >= 0; })) {
            console.log("[file-exists] " + path + " -> " + result);
        }

        return result;
    };

    console.log("[file-exists] Hook active for root/emulator/frida path probes");
});
