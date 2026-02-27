#!/usr/bin/env bash
# Security collectors for system report generation.

collect_security() {
	section "Security"

	local items=()

	if [[ "$HAS_FAIL2BAN" == "true" ]] && command -v fail2ban-client &>/dev/null; then
		local fail2ban_status banned total_bans
		fail2ban_status=$(safe_cmd sudo fail2ban-client status sshd 2>/dev/null)
		banned=$(echo "$fail2ban_status" | grep "Currently banned" | awk '{print $NF}') || banned="?"
		total_bans=$(echo "$fail2ban_status" | grep "Total banned" | awk '{print $NF}') || total_bans="?"
		items+=("- fail2ban: ${banned:-0} currently banned, ${total_bans:-0} total bans (sshd)")
		_FAIL2BAN_BANNED="${banned:-0}"
	else
		items+=("- fail2ban: [unavailable]")
		_FAIL2BAN_BANNED="0"
	fi

	local lynis_output
	lynis_output=$(safe_cmd journalctl -u security-audit --no-pager -n 50 --since "-7d" 2>/dev/null)
	if [[ -n "$lynis_output" ]]; then
		local score
		score=$(echo "$lynis_output" | grep -oP 'Hardening index : \K[0-9]+' | tail -1 || echo "")
		if [[ -n "$score" ]]; then
			items+=("- Lynis audit score: ${score}/100")
		else
			items+=("- Lynis: no recent audit score found")
		fi
	else
		items+=("- Lynis: [unavailable]")
	fi

	if [[ "$HAS_OPENSNITCH" == "true" ]]; then
		local blocked
		blocked=$(safe_cmd journalctl -u opensnitchd --no-pager --since "-24h" -o json 2>/dev/null |
			jq -rs '[.[] | select(.MESSAGE? | test("blocked"; "i"))] | length' 2>/dev/null || echo "0")
		items+=("- OpenSnitch: ${blocked:-0} blocked connections (24h)")
	else
		items+=("- OpenSnitch: [unavailable]")
	fi

	if command -v systemd-analyze &>/dev/null; then
		local exposed
		exposed=$(safe_cmd systemd-analyze security --no-pager 2>/dev/null |
			awk '$NF == "EXPOSED" || $NF == "UNSAFE" {count++} END {print count+0}') || exposed="0"
		items+=("- systemd unit hardening: ${exposed} units rated EXPOSED/UNSAFE")
	fi

	printf '%s\n' "${items[@]}"
}
