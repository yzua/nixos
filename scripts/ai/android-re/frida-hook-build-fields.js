// Frida script: Log android.os.Build fields visible to the target app.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-build-fields.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-build-fields.js

Java.perform(function () {
    var Build = Java.use("android.os.Build");
    var fields = [
        "BOARD",
        "BRAND",
        "DEVICE",
        "FINGERPRINT",
        "HARDWARE",
        "MANUFACTURER",
        "MODEL",
        "PRODUCT",
        "TAGS",
        "TYPE",
    ];

    console.log("[build-fields] Visible Build values:");
    fields.forEach(function (field) {
        try {
            console.log("[build-fields] " + field + "=" + Build[field].value);
        } catch (error) {
            console.log("[build-fields] " + field + "=<error: " + error + ">");
        }
    });
});
