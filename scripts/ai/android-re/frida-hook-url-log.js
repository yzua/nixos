// Frida script: Log URL creation and OkHttp request URLs when available.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-url-log.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-url-log.js

Java.perform(function () {
    var URL = Java.use("java.net.URL");
    var RequestBuilder;
    var requestBuilderUrl;
    var urlInit = URL.$init.overload("java.lang.String");

    urlInit.implementation = function (url) {
        console.log("[url-log:url] " + url);
        return urlInit.call(this, url);
    };

    try {
        RequestBuilder = Java.use("okhttp3.Request$Builder");
        requestBuilderUrl = RequestBuilder.url.overload("java.lang.String");
        requestBuilderUrl.implementation = function (url) {
            console.log("[url-log:okhttp] " + url);
            return requestBuilderUrl.call(this, url);
        };
    } catch (error) {
        console.log("[url-log] okhttp3.Request$Builder not available: " + error);
    }

    console.log("[url-log] Hook active for URL construction");
});
