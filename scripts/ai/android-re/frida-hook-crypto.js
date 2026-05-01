// Frida script: Log cryptographic operations (Cipher, Mac, MessageDigest, Signature).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-crypto.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-crypto.js

Java.perform(() => {
	// javax.crypto.Cipher
	try {
		var Cipher = Java.use("javax.crypto.Cipher");
		Cipher.init.overload("int", "java.security.Key").implementation = function (
			opmode,
			key,
		) {
			var alg = this.getAlgorithm();
			var mode =
				opmode === 1 ? "ENCRYPT" : opmode === 2 ? "DECRYPT" : String(opmode);
			console.log("[crypto:cipher.init] mode=" + mode + " algorithm=" + alg);
			return this.init(opmode, key);
		};
		Cipher.init.overload(
			"int",
			"java.security.Key",
			"java.security.spec.AlgorithmParameterSpec",
		).implementation = function (opmode, key, params) {
			var alg = this.getAlgorithm();
			var mode =
				opmode === 1 ? "ENCRYPT" : opmode === 2 ? "DECRYPT" : String(opmode);
			console.log(
				"[crypto:cipher.init] mode=" +
					mode +
					" algorithm=" +
					alg +
					" params=" +
					String(params),
			);
			return this.init(opmode, key, params);
		};
		Cipher.doFinal.overload("[B").implementation = function (input) {
			var alg = this.getAlgorithm();
			var inLen = input ? input.length : 0;
			var result = this.doFinal(input);
			var outLen = result ? result.length : 0;
			console.log(
				"[crypto:cipher.doFinal] algorithm=" +
					alg +
					" in=" +
					inLen +
					"B out=" +
					outLen +
					"B",
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] Cipher hook skipped: " + e.message);
	}

	// javax.crypto.Mac
	try {
		var Mac = Java.use("javax.crypto.Mac");
		Mac.update.overload("[B").implementation = function (input) {
			console.log(
				"[crypto:mac.update] algorithm=" +
					this.getAlgorithm() +
					" input=" +
					(input ? input.length : 0) +
					"B",
			);
			return this.update(input);
		};
		Mac.doFinal.implementation = function () {
			var result = this.doFinal();
			console.log(
				"[crypto:mac.doFinal] algorithm=" +
					this.getAlgorithm() +
					" out=" +
					(result ? result.length : 0) +
					"B",
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] Mac hook skipped: " + e.message);
	}

	// java.security.MessageDigest
	try {
		var MessageDigest = Java.use("java.security.MessageDigest");
		MessageDigest.digest.overload("[B").implementation = function (input) {
			var alg = this.getAlgorithm();
			var result = this.digest(input);
			var hex = "";
			for (var i = 0; i < Math.min(result.length, 32); i++) {
				hex += ("0" + (result[i] & 0xff).toString(16)).slice(-2);
			}
			console.log(
				"[crypto:digest] algorithm=" +
					alg +
					" in=" +
					(input ? input.length : 0) +
					"B hash=" +
					hex +
					(result.length > 32 ? "..." : ""),
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] MessageDigest hook skipped: " + e.message);
	}

	// java.security.Signature
	try {
		var Signature = Java.use("java.security.Signature");
		Signature.sign.implementation = function () {
			var result = this.sign();
			console.log(
				"[crypto:signature.sign] algorithm=" +
					this.getAlgorithm() +
					" out=" +
					(result ? result.length : 0) +
					"B",
			);
			return result;
		};
		Signature.verify.overload("[B").implementation = function (signature) {
			var result = this.verify(signature);
			console.log(
				"[crypto:signature.verify] algorithm=" +
					this.getAlgorithm() +
					" result=" +
					result,
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] Signature hook skipped: " + e.message);
	}

	console.log(
		"[crypto] Hook active for crypto operations (Cipher, Mac, MessageDigest, Signature)",
	);
});
