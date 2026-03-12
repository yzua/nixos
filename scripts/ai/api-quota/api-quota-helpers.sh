#!/usr/bin/env bash
# Shared helper functions for api-quota providers and rendering.

progress_bar() {
	local pct="$1"
	local width=12
	local fill i bar=""
	if [[ ! "$pct" =~ ^[0-9]+$ ]]; then
		printf "%s" "------------"
		return
	fi
	if ((pct < 0)); then pct=0; fi
	if ((pct > 100)); then pct=100; fi
	fill=$((pct * width / 100))
	for ((i = 0; i < fill; i++)); do bar+="#"; done
	for ((i = fill; i < width; i++)); do bar+="-"; done
	printf "%s" "$bar"
}

remaining_color() {
	local remaining="$1"
	if [[ ! "$remaining" =~ ^[0-9]+$ ]]; then
		printf "#a89984"
	elif ((remaining <= 20)); then
		printf "#fb4934"
	elif ((remaining <= 40)); then
		printf "#fabd2f"
	else
		printf "#b8bb26"
	fi
}

format_tokens() {
	local val="$1"
	local val_int
	if [[ -z "$val" || "$val" == "null" ]]; then
		printf "?"
		return
	fi
	if [[ ! "$val" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
		printf "?"
		return
	fi
	val_int=$(printf "%.0f" "$val")
	if ((val_int >= 1000000)); then
		printf "%.1fM" "$(echo "$val / 1000000" | bc -l)"
	elif ((val_int >= 1000)); then
		printf "%.0fK" "$(echo "$val / 1000" | bc -l)"
	else
		printf "%s" "$val_int"
	fi
}

time_until() {
	local now diff h m
	now=$(date +%s)
	diff=$(($1 - now))
	if ((diff <= 0)); then
		printf "now"
		return
	fi
	h=$((diff / 3600))
	m=$(((diff % 3600) / 60))
	if ((h > 0)); then printf "%dh %dm" "$h" "$m"; else printf "%dm" "$m"; fi
}

numeric_pct_to_remaining() {
	local used_pct="$1"
	local used_int
	if [[ ! "$used_pct" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
		return 1
	fi
	used_int=$(printf "%.0f" "$used_pct")
	if ((used_int < 0)); then used_int=0; fi
	if ((used_int > 100)); then used_int=100; fi
	printf "%d" "$((100 - used_int))"
}

resolve_reset_epoch() {
	local reset_value="$1"
	local reset_format="$2"
	case "$reset_format" in
	epoch)
		if [[ "$reset_value" =~ ^[0-9]+$ ]]; then
			printf "%s" "$reset_value"
			return 0
		fi
		;;
	iso8601)
		date -d "$reset_value" +%s 2>/dev/null || return 1
		return 0
		;;
	esac
	return 1
}

build_window_tip() {
	local title="$1"
	local used_pct="$2"
	local reset_value="$3"
	local seven_day_pct="$4"
	local reset_format="${5:-none}"

	local remaining color tip
	remaining=$(numeric_pct_to_remaining "$used_pct") || return 1
	color=$(remaining_color "$remaining")

	tip="<b>${title}</b> <span style='color:${color}'><b>${remaining}% left</b></span>"
	tip+="${NL}<tt>Left: [$(progress_bar "$remaining")] ${remaining}%</tt>"
	tip+="${NL}5h used: $(printf "%.1f" "$used_pct")%"

	local epoch
	if epoch=$(resolve_reset_epoch "$reset_value" "$reset_format"); then
		tip+=" | Reset: $(time_until "$epoch")"
	fi

	if [[ -n "$seven_day_pct" ]]; then
		local seven_remaining
		if seven_remaining=$(numeric_pct_to_remaining "$seven_day_pct"); then
			tip+="${NL}7d used: $(printf "%.1f" "$seven_day_pct")% (left ${seven_remaining}%)"
		fi
	fi

	printf "%s" "$tip"
}

cache_mtime_epoch() {
	local file="$1"
	stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo ""
}

read_cache() {
	local f="${CACHE_DIR}/${1}.json"
	if [[ -f "$f" ]]; then
		local mtime age
		mtime=$(cache_mtime_epoch "$f")
		if [[ -z "$mtime" ]]; then
			return 1
		fi
		age=$(($(date +%s) - mtime))
		if ((age < CACHE_TTL)); then
			cat "$f"
			return 0
		fi
	fi
	return 1
}

write_cache() {
	mkdir -p "$CACHE_DIR"
	printf '%s' "$2" >"${CACHE_DIR}/${1}.json"
}

output_error() { jq -c -n --arg tip "$1" '{"pct":"?","tip":$tip}'; }

fetch_cached_response() {
	local cache_key="$1"
	local endpoint="$2"
	shift 2

	local response
	if ! response=$(read_cache "$cache_key"); then
		response=$(curl -s -m 8 -f "$endpoint" "$@" 2>/dev/null) || response=""
		[[ -n "$response" ]] && write_cache "$cache_key" "$response"
	fi
	printf "%s" "$response"
}
