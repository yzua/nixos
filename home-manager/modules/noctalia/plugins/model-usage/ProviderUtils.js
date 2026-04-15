.pragma library

var _base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

function formatResetTime(isoTimestamp) {
	if (!isoTimestamp) return "";
	var reset = new Date(isoTimestamp);
	var now = new Date();
	var diffMs = reset.getTime() - now.getTime();
	if (diffMs <= 0) return "now";
	var hours = Math.floor(diffMs / 3600000);
	var mins = Math.floor((diffMs % 3600000) / 60000);
	if (hours > 24) return Math.floor(hours / 24) + "d " + (hours % 24) + "h";
	if (hours > 0) return hours + "h " + mins + "m";
	return mins + "m";
}

function localDateString() {
	var now = new Date();
	var y = now.getFullYear();
	var m = String(now.getMonth() + 1).padStart(2, "0");
	var d = String(now.getDate()).padStart(2, "0");
	return y + "-" + m + "-" + d;
}

function dateDaysAgoString(daysAgo) {
	var dt = new Date();
	dt.setHours(0, 0, 0, 0);
	dt.setDate(dt.getDate() - daysAgo);
	var y = dt.getFullYear();
	var m = String(dt.getMonth() + 1).padStart(2, "0");
	var d = String(dt.getDate()).padStart(2, "0");
	return y + "-" + m + "-" + d;
}

function resolvePath(p, homeDir) {
	if (p && p.startsWith("~")) return (homeDir || "/home") + p.substring(1);
	return p;
}

function normalizeResetAt(value) {
	if (value === null || value === undefined || value === "") return "";
	if (typeof value === "number" && isFinite(value)) {
		var ts = value;
		if (ts < 1e12) ts *= 1000;
		var d = new Date(ts);
		if (!isNaN(d.getTime())) return d.toISOString();
		return "";
	}
	var raw = String(value).trim();
	if (raw === "") return "";
	if (/^\d+$/.test(raw)) {
		var ts2 = parseInt(raw, 10);
		if (ts2 < 1e12) ts2 *= 1000;
		var d2 = new Date(ts2);
		if (!isNaN(d2.getTime())) return d2.toISOString();
	}
	var parsed = new Date(raw);
	if (!isNaN(parsed.getTime())) return parsed.toISOString();
	return "";
}

function shortId(value, head, tail) {
	if (!value) return "";
	var raw = String(value);
	var start = head || 8;
	var end = tail || 6;
	if (raw.length <= start + end + 1) return raw;
	return raw.slice(0, start) + "…" + raw.slice(-end);
}

function formatShortDate(value) {
	var iso = normalizeResetAt(value);
	if (!iso) return "";
	var d = new Date(iso);
	if (isNaN(d.getTime())) return "";
	var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	return d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear();
}

function formatDateRange(startValue, endValue) {
	var start = formatShortDate(startValue);
	var end = formatShortDate(endValue);
	if (start && end) return start + " → " + end;
	return start || end;
}

function humanizeIdentifier(value) {
	if (!value) return "";
	var text = String(value).replace(/[_-]+/g, " ").trim();
	if (!text) return "";
	return text.split(/\s+/).map(function(part) {
		if (!part) return "";
		if (/^[A-Z0-9]+$/.test(part)) return part;
		return part.charAt(0).toUpperCase() + part.slice(1);
	}).join(" ");
}

function _decodeBase64(base64) {
	var clean = String(base64 || "").replace(/\s+/g, "");
	var output = [];
	var buffer = 0;
	var bits = 0;
	for (var i = 0; i < clean.length; i++) {
		var ch = clean.charAt(i);
		if (ch === "=") break;
		var idx = _base64Alphabet.indexOf(ch);
		if (idx < 0) continue;
		buffer = (buffer << 6) | idx;
		bits += 6;
		if (bits >= 8) {
			bits -= 8;
			output.push(String.fromCharCode((buffer >> bits) & 0xff));
		}
	}
	return output.join("");
}

function decodeBase64UrlToUtf8(value) {
	if (!value) return "";
	var normalized = String(value).replace(/-/g, "+").replace(/_/g, "/");
	while (normalized.length % 4 !== 0)
		normalized += "=";
	var binary = _decodeBase64(normalized);
	var encoded = "";
	for (var i = 0; i < binary.length; i++)
		encoded += "%" + ("00" + binary.charCodeAt(i).toString(16)).slice(-2);
	try {
		return decodeURIComponent(encoded);
	} catch (e) {
		return binary;
	}
}

function parseJwtPayload(token) {
	if (!token) return null;
	var parts = String(token).split(".");
	if (parts.length < 2) return null;
	try {
		return JSON.parse(decodeBase64UrlToUtf8(parts[1]));
	} catch (e) {
		return null;
	}
}
