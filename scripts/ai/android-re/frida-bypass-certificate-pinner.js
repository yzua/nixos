// Frida script: Bypass common OkHttp CertificatePinner and TrustManager checks.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-bypass-certificate-pinner.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-bypass-certificate-pinner.js

Java.perform(function () {
    var CertificatePinner;
    var certificatePinnerCheck;
    var TrustManagerImpl;
    var verifyChain;

    try {
        CertificatePinner = Java.use("okhttp3.CertificatePinner");
        certificatePinnerCheck = CertificatePinner.check.overload("java.lang.String", "java.util.List");

        certificatePinnerCheck.implementation = function (host, peerCertificates) {
            console.log("[cert-bypass] Bypassing CertificatePinner for host=" + host);
            return;
        };

        console.log("[cert-bypass] OkHttp CertificatePinner bypass active");
    } catch (error) {
        console.log("[cert-bypass] okhttp3.CertificatePinner not available: " + error);
    }

    try {
        TrustManagerImpl = Java.use("com.android.org.conscrypt.TrustManagerImpl");
        verifyChain = TrustManagerImpl.verifyChain.overload(
            "java.util.List",
            "java.util.List",
            "java.lang.String",
            "boolean",
            "byte[]",
            "byte[]"
        );

        verifyChain.implementation = function (untrustedChain, trustAnchorChain, host, clientAuth, ocspData, tlsSctData) {
            console.log("[cert-bypass] Bypassing TrustManagerImpl.verifyChain for host=" + host);
            return untrustedChain;
        };

        console.log("[cert-bypass] Conscrypt TrustManagerImpl bypass active");
    } catch (error) {
        console.log("[cert-bypass] TrustManagerImpl not available: " + error);
    }
});
