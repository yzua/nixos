// Frida script: Log SharedPreferences reads and writes for secrets/token triage.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-shared-prefs.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-shared-prefs.js

Java.perform(function () {
    var SharedPreferencesImpl = Java.use("android.app.SharedPreferencesImpl");
    var EditorImpl = Java.use("android.app.SharedPreferencesImpl$EditorImpl");
    var getString = SharedPreferencesImpl.getString.overload("java.lang.String", "java.lang.String");
    var getBoolean = SharedPreferencesImpl.getBoolean.overload("java.lang.String", "boolean");
    var putString = EditorImpl.putString.overload("java.lang.String", "java.lang.String");

    getString.implementation = function (key, defValue) {
        var value = getString.call(this, key, defValue);
        console.log("[shared-prefs:getString] " + key + " = " + value);
        return value;
    };

    getBoolean.implementation = function (key, defValue) {
        var value = getBoolean.call(this, key, defValue);
        console.log("[shared-prefs:getBoolean] " + key + " = " + value);
        return value;
    };

    putString.implementation = function (key, value) {
        console.log("[shared-prefs:putString] " + key + " = " + value);
        return putString.call(this, key, value);
    };

    console.log("[shared-prefs] Hook active for SharedPreferences reads/writes");
});
