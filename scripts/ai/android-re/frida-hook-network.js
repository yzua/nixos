// Frida script: Log network connections (Socket.connect, SSLSocket, OkHttp, HttpURLConnection).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-network.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-network.js

Java.perform(() => {
	// java.net.Socket.connect
	try {
		var Socket = Java.use("java.net.Socket");
		var InetSocketAddress = Java.use("java.net.InetSocketAddress");
		Socket.connect.overload("java.net.SocketAddress", "int").implementation =
			function (addr, timeout) {
				try {
					var inetAddr = Java.cast(addr, InetSocketAddress);
					console.log(
						"[network:connect] " +
							inetAddr.getHostString() +
							":" +
							inetAddr.getPort() +
							" timeout=" +
							timeout,
					);
				} catch (e) {
					console.log("[network:connect] " + addr + " timeout=" + timeout);
				}
				return this.connect(addr, timeout);
			};
		Socket.connect.overload("java.net.SocketAddress").implementation =
			function (addr) {
				try {
					var inetAddr = Java.cast(addr, InetSocketAddress);
					console.log(
						"[network:connect] " +
							inetAddr.getHostString() +
							":" +
							inetAddr.getPort(),
					);
				} catch (e) {
					console.log("[network:connect] " + addr);
				}
				return this.connect(addr);
			};
	} catch (e) {
		console.log("[network] Socket.connect hook skipped: " + e.message);
	}

	// javax.net.ssl.SSLSocket.startHandshake
	try {
		var SSLSocket = Java.use("javax.net.ssl.SSLSocket");
		SSLSocket.startHandshake.implementation = function () {
			var host = "?";
			var port = 0;
			try {
				var inetAddr = Java.cast(
					this.getInetAddress(),
					Java.use("java.net.InetAddress"),
				);
				host = inetAddr.getHostAddress();
				port = this.getPort();
			} catch (e2) {}
			console.log("[network:tls] handshake start " + host + ":" + port);
			return this.startHandshake();
		};
	} catch (e) {
		console.log(
			"[network] SSLSocket.startHandshake hook skipped: " + e.message,
		);
	}

	// okhttp3.RealCall.execute
	try {
		var RealCall = Java.use("okhttp3.RealCall");
		RealCall.execute.implementation = function () {
			var url = "?";
			var method = "?";
			try {
				var req = this.request();
				url = req.url().toString();
				method = req.method();
			} catch (e2) {}
			console.log("[network:okhttp] " + method + " " + url);
			return this.execute();
		};
	} catch (e) {
		console.log("[network] OkHttp RealCall.execute hook skipped: " + e.message);
	}

	// java.net.HttpURLConnection.connect
	try {
		var HttpURLConnection = Java.use("java.net.HttpURLConnection");
		HttpURLConnection.connect.implementation = function () {
			var url = "?";
			try {
				url = this.getURL().toString();
			} catch (e2) {}
			console.log("[network:http] connect " + url);
			return this.connect();
		};
	} catch (e) {
		console.log(
			"[network] HttpURLConnection.connect hook skipped: " + e.message,
		);
	}

	console.log(
		"[network] Hook active for network connections (Socket, SSLSocket, OkHttp, HttpURLConnection)",
	);
});
