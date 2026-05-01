// Frida script: Log Intent and IPC operations (startActivity, BroadcastReceiver, ContentResolver).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-intent.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-intent.js

function logIntent(tag, intent) {
	if (!intent) {
		console.log(tag + " intent=null");
		return;
	}
	var action = "?";
	var data = "?";
	var extras = "";
	try {
		action = intent.getAction() || "none";
	} catch (e) {}
	try {
		data = intent.getDataString() || "none";
	} catch (e) {}
	try {
		var bundle = intent.getExtras();
		if (bundle) {
			var keys = bundle.keySet();
			var arr = keys.toArray();
			extras = " extras=[" + arr.join(", ") + "]";
		}
	} catch (e) {}
	console.log(tag + " action=" + action + " data=" + data + extras);
}

Java.perform(() => {
	// Activity.startActivity(Intent)
	try {
		var Activity = Java.use("android.app.Activity");
		Activity.startActivity.overload("android.content.Intent").implementation =
			function (intent) {
				logIntent("[intent:activity.start]", intent);
				return this.startActivity(intent);
			};
		Activity.startActivity.overload(
			"android.content.Intent",
			"android.os.Bundle",
		).implementation = function (intent, bundle) {
			logIntent("[intent:activity.start]", intent);
			return this.startActivity(intent, bundle);
		};
	} catch (e) {
		console.log("[intent] Activity.startActivity hook skipped: " + e.message);
	}

	// ContextWrapper.startActivity
	try {
		var ContextWrapper = Java.use("android.content.ContextWrapper");
		ContextWrapper.startActivity.overload(
			"android.content.Intent",
		).implementation = function (intent) {
			logIntent("[intent:context.start]", intent);
			return this.startActivity(intent);
		};
	} catch (e) {
		console.log(
			"[intent] ContextWrapper.startActivity hook skipped: " + e.message,
		);
	}

	// BroadcastReceiver.onReceive
	try {
		var BroadcastReceiver = Java.use("android.content.BroadcastReceiver");
		BroadcastReceiver.onReceive.implementation = function (context, intent) {
			logIntent("[intent:broadcast.recv]", intent);
			return this.onReceive(context, intent);
		};
	} catch (e) {
		console.log(
			"[intent] BroadcastReceiver.onReceive hook skipped: " + e.message,
		);
	}

	// ContentResolver.query
	try {
		var ContentResolver = Java.use("android.content.ContentResolver");
		ContentResolver.query.overload(
			"android.net.Uri",
			"[Ljava.lang.String;",
			"java.lang.String",
			"[Ljava.lang.String;",
			"java.lang.String",
		).implementation = function (
			uri,
			projection,
			selection,
			selectionArgs,
			sortOrder,
		) {
			console.log(
				"[intent:content.query] uri=" +
					uri +
					" selection=" +
					(selection || "none") +
					" projection=" +
					(projection ? projection.length + " cols" : "none"),
			);
			return this.query(uri, projection, selection, selectionArgs, sortOrder);
		};
	} catch (e) {
		console.log("[intent] ContentResolver.query hook skipped: " + e.message);
	}

	console.log(
		"[intent] Hook active for Intent/IPC operations (startActivity, broadcast, content query)",
	);
});
