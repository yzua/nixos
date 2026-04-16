// Frida script: Override android.os.Build fields to match the Pixel 7 spoof profile.
// This closes the gap where resetprop fixes shell-level props but Java-level
// Build fields (cached by Zygote at startup) still show emulator values.
//
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-spoof-build.js
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-spoof-build.js --no-pause

// Pixel 7 (panther) profile — must match _spoof-table.sh values
var SPOOF = {
	BOARD: "gs101",
	BRAND: "google",
	DEVICE: "panther",
	DISPLAY: "UQ1A.240205.002",
	FINGERPRINT:
		"google/panther/panther:14/UQ1A.240205.002/12069354:user/release-keys",
	HARDWARE: "pixel",
	HOST: "abfarm-release-rbe-64-00075",
	ID: "UQ1A.240205.002",
	MANUFACTURER: "Google",
	MODEL: "Pixel 7",
	PRODUCT: "panther",
	SERIAL: "",
	TAGS: "release-keys",
	TYPE: "user",
};

var HIDDEN_PATHS = [
	"/dev/goldfish_pipe",
	"/dev/qemu_pipe",
	"/dev/socket/genyd",
	"/dev/socket/genymotion",
	"/system/lib/libgoldfish-ril.so",
	"/system/lib64/libgoldfish-ril.so",
	"/system/lib/libgoldfish_icd.so",
	"/system/lib64/libgoldfish_icd.so",
];

Java.perform(() => {
	var Build = Java.use("android.os.Build");
	var BuildVersion;
	var File;
	var fields = Object.keys(SPOOF);
	var patched = 0;
	var failed = 0;
	var idx;
	var value;

	// Override static Build fields
	for (idx = 0; idx < fields.length; idx++) {
		value = SPOOF[fields[idx]];
		if (value === "") continue;
		try {
			Build[fields[idx]].value = value;
			patched++;
		} catch (e) {
			failed++;
			console.log("[spoof-build] FAILED: " + fields[idx] + " -> " + e);
		}
	}

	// Build.VERSION.CODENAME
	try {
		BuildVersion = Java.use("android.os.Build$VERSION");
		if (BuildVersion.CODENAME) {
			BuildVersion.CODENAME.value = "REL";
		}
	} catch (e) {
		// ignore
	}

	console.log(
		"[spoof-build] Patched " +
			patched +
			" Build fields" +
			(failed > 0 ? " (" + failed + " failed)" : ""),
	);
	console.log(
		"[spoof-build] MODEL=" +
			Build.MODEL.value +
			" HARDWARE=" +
			Build.HARDWARE.value +
			" MFG=" +
			Build.MANUFACTURER.value,
	);

	// Hook File.exists to hide emulator-indicator files
	File = Java.use("java.io.File");
	File.exists.implementation = function () {
		var path = this.getAbsolutePath();
		for (idx = 0; idx < HIDDEN_PATHS.length; idx++) {
			if (path === HIDDEN_PATHS[idx]) {
				return false;
			}
		}
		return this.exists();
	};

	console.log(
		"[spoof-build] File.exists hook active for " +
			HIDDEN_PATHS.length +
			" emulator paths",
	);
});
