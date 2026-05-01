// Frida script: Log WebView operations (loadUrl, evaluateJavascript, interfaces, overrides).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-webview.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-webview.js

Java.perform(() => {
	// WebView.loadUrl
	try {
		var WebView = Java.use("android.webkit.WebView");
		WebView.loadUrl.overload("java.lang.String").implementation = function (
			url,
		) {
			console.log("[webview:loadUrl] " + url);
			return this.loadUrl(url);
		};
		WebView.loadUrl.overload(
			"java.lang.String",
			"java.util.Map",
		).implementation = function (url, headers) {
			console.log(
				"[webview:loadUrl] " +
					url +
					" headers=" +
					(headers ? headers.keySet() : "none"),
			);
			return this.loadUrl(url, headers);
		};
	} catch (e) {
		console.log("[webview] WebView.loadUrl hook skipped: " + e.message);
	}

	// WebView.evaluateJavascript
	try {
		var WebView = Java.use("android.webkit.WebView");
		WebView.evaluateJavascript.implementation = function (script, callback) {
			var snippet =
				script.length > 200 ? script.substring(0, 200) + "..." : script;
			console.log("[webview:evalJS] " + snippet);
			return this.evaluateJavascript(script, callback);
		};
	} catch (e) {
		console.log(
			"[webview] WebView.evaluateJavascript hook skipped: " + e.message,
		);
	}

	// WebView.addJavascriptInterface
	try {
		var WebView = Java.use("android.webkit.WebView");
		WebView.addJavascriptInterface.implementation = function (obj, name) {
			console.log(
				"[webview:jsInterface] name=" +
					name +
					" class=" +
					(obj ? obj.getClass().getName() : "null"),
			);
			return this.addJavascriptInterface(obj, name);
		};
	} catch (e) {
		console.log(
			"[webview] WebView.addJavascriptInterface hook skipped: " + e.message,
		);
	}

	// WebViewClient.shouldOverrideUrlLoading
	try {
		var WebViewClient = Java.use("android.webkit.WebViewClient");
		WebViewClient.shouldOverrideUrlLoading.overload(
			"android.webkit.WebView",
			"java.lang.String",
		).implementation = function (view, url) {
			console.log("[webview:overrideUrl] " + url);
			return this.shouldOverrideUrlLoading(view, url);
		};
	} catch (e) {
		console.log(
			"[webview] WebViewClient.shouldOverrideUrlLoading(String) hook skipped: " +
				e.message,
		);
	}
	try {
		var WebViewClient2 = Java.use("android.webkit.WebViewClient");
		WebViewClient2.shouldOverrideUrlLoading.overload(
			"android.webkit.WebView",
			"android.webkit.WebResourceRequest",
		).implementation = function (view, request) {
			console.log(
				"[webview:overrideUrl] " +
					request.getUrl() +
					" method=" +
					request.getMethod(),
			);
			return this.shouldOverrideUrlLoading(view, request);
		};
	} catch (e) {
		console.log(
			"[webview] WebViewClient.shouldOverrideUrlLoading(WebResourceRequest) hook skipped: " +
				e.message,
		);
	}

	// WebSettings.setJavaScriptEnabled
	try {
		var WebSettings = Java.use("android.webkit.WebSettings");
		WebSettings.setJavaScriptEnabled.implementation = function (flag) {
			console.log("[webview:jsEnabled] " + flag);
			return this.setJavaScriptEnabled(flag);
		};
	} catch (e) {
		console.log(
			"[webview] WebSettings.setJavaScriptEnabled hook skipped: " + e.message,
		);
	}

	console.log(
		"[webview] Hook active for WebView operations (loadUrl, evalJS, jsInterface, overrideUrl, jsEnabled)",
	);
});
