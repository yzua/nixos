# Session Memory and Learning System

## Why Persistent Memory

Each assessment session starts from scratch — the agent must re-learn the target, re-discover
known patterns, and re-attempt failed approaches. Persistent memory solves this by recording:

- Which strategies and bypasses worked (and which didn't)
- Payload formats that triggered vulnerabilities
- WAF bypass techniques that succeeded
- Target-specific quirks and behaviors
- Tool configurations that produced results

Over time, the memory system makes the agent more effective by avoiding repeated dead ends
and prioritizing proven techniques.

## Memory Store Location

Each target has its own memory store at:

```
~/Documents/<target>/memory.json
```

This file persists across sessions and grows with each assessment. Read it at session start,
update it during the session, and write changes immediately (same discipline as workspace files).

## Memory Schema

The memory file is a JSON object with these top-level sections:

```json
{
  "target": "example.target.com",
  "created": "2025-01-15",
  "last_updated": "2025-01-20",
  "sessions_completed": 5,
  "knowledge": {
    "strategy": [],
    "bypass": [],
    "payload": [],
    "target_quirk": [],
    "tool_config": [],
    "waf_evasion": []
  },
  "session_history": []
}
```

## Knowledge Types

### Strategy Knowledge

Records which testing approaches worked and which didn't, with confidence scores.

```json
{
  "type": "strategy",
  "category": "auth_testing",
  "description": "JWT algorithm confusion attack — alg:none bypass accepted",
  "target_component": "/api/auth/login",
  "confidence": 0.9,
  "success_count": 1,
  "failure_count": 0,
  "last_seen": "2025-01-18T14:30:00Z",
  "details": "Sending JWT with alg:none and removing signature grants admin access"
}
```

Categories: `recon`, `auth_testing`, `injection`, `client_side`, `api_testing`,
`config_review`, `crypto_analysis`, `network_analysis`, `session_testing`

### Bypass Knowledge

Records specific bypass techniques that defeated security controls.

```json
{
  "type": "bypass",
  "category": "waf_bypass",
  "description": "Double URL-encoding bypasses WAF SQL injection rules",
  "target_component": "/api/search?q=",
  "confidence": 0.85,
  "success_count": 2,
  "failure_count": 0,
  "last_seen": "2025-01-19T10:15:00Z",
  "details": "%27 becomes %2527 which WAF doesn't decode but backend does"
}
```

Categories: `waf_bypass`, `rate_limit_bypass`, `auth_bypass`, `cors_bypass`,
`csrf_bypass`, `csp_bypass`, `idor_bypass`, `serialization_bypass`

### Payload Knowledge

Records specific payload formats that triggered vulnerabilities.

```json
{
  "type": "payload",
  "category": "xss",
  "description": "Reflected XSS via img onerror in search parameter",
  "target_component": "/search?q=",
  "confidence": 0.9,
  "success_count": 1,
  "failure_count": 0,
  "last_seen": "2025-01-18T16:45:00Z",
  "payload": "<img src=x onerror=alert(1)>",
  "response_indicator": "Payload reflected unescaped in HTML body",
  "context": "No CSP, no output encoding on search results page"
}
```

Categories: `sql_injection`, `xss`, `command_injection`, `path_traversal`,
`ssrf`, `prototype_pollution`, `open_redirect`, `csrf`, `jwt_attack`,
`deserialization`

### Target Quirk Knowledge

Records target-specific behaviors that differ from standard expectations.

```json
{
  "type": "target_quirk",
  "category": "session_management",
  "description": "Session cookies valid for 24h, no server-side invalidation on logout",
  "target_component": "/api/auth/logout",
  "confidence": 1.0,
  "last_seen": "2025-01-17T09:00:00Z",
  "details": "Logout returns 200 but old session cookie still works for 24h"
}
```

Categories: `authentication`, `session_management`, `api_behavior`,
`error_handling`, `rate_limiting`, `encoding`, `cors`, `csp`, `headers`

### Tool Configuration Knowledge

Records tool configurations that produced useful results.

```json
{
  "type": "tool_config",
  "category": "nuclei",
  "description": "Custom nuclei template for JWT none algorithm check",
  "confidence": 0.9,
  "success_count": 3,
  "failure_count": 0,
  "last_seen": "2025-01-20T11:30:00Z",
  "config": "nuclei -t jwt-none-alg.yaml -u https://target.com",
  "notes": "Catches JWT implementations that accept alg:none"
}
```

Categories: `nuclei`, `sqlmap`, `nmap`, `ffuf`, `burp`, `mitmproxy`,
`semgrep`, `codeql`, `katana`, `custom_script`, `chrome_devtools`

### WAF Evasion Knowledge

Records WAF detection and evasion techniques specific to this target.

```json
{
  "type": "waf_evasion",
  "category": "encoding_bypass",
  "description": "Unicode normalization bypasses XSS filter",
  "target_component": "/api/comment",
  "confidence": 0.8,
  "success_count": 1,
  "failure_count": 0,
  "last_seen": "2025-01-19T14:20:00Z",
  "payload": "＜script＞alert(1)＜/script＞",
  "details": "Fullwidth Unicode characters normalized to ASCII by backend"
}
```

## Confidence Scoring

Every knowledge entry has a confidence score between 0.0 and 1.0:

- **0.9-1.0** — Proven, reproduced multiple times
- **0.7-0.89** — Strong evidence, reproduced at least once
- **0.5-0.69** — Likely, indirect evidence
- **0.3-0.49** — Suspected, needs validation
- **0.0-0.29** — Weak, insufficient evidence

### Adjustment Rules

On success (technique worked):

```
confidence = min(1.0, confidence + 0.1)
success_count += 1
```

On failure (technique didn't work):

```
confidence = max(0.0, confidence - 0.05)
failure_count += 1
```

On repeated failure (3+ consecutive failures):

```
confidence = max(0.0, confidence - 0.1)
# Consider marking as "blocked" or "deprecated"
```

## Session History

Each session appends an entry to the `session_history` array:

```json
{
  "session_id": "2025-01-20-001",
  "date": "2025-01-20",
  "duration_minutes": 120,
  "goals": ["Test authentication bypass", "Map API endpoints"],
  "findings": ["JWT alg:none bypass confirmed", "SQL injection on /api/search"],
  "strategies_tried": ["jwt_confusion", "sqlmap_auth_bypass"],
  "strategies_succeeded": ["jwt_confusion"],
  "strategies_failed": ["brute_force_login"],
  "blocked_items": ["Rate limiting prevents automated testing on /api/login"],
  "next_steps": [
    "Test IDOR on /api/users/{id}",
    "Check CORS on admin endpoints"
  ],
  "knowledge_added": 3,
  "knowledge_updated": 1
}
```

## Session Workflow

### At Session Start

Load context from existing memory:

```bash
# High-confidence strategies, bypasses, and WAF evasions
jq '[.knowledge | to_entries[] | .value[] | select(.confidence >= 0.7)]' ~/Documents/<target>/memory.json

# Failed strategies to avoid
jq '[.knowledge.strategy[] | select(.confidence < 0.3)]' ~/Documents/<target>/memory.json

# WAF evasion knowledge
jq '[.knowledge.waf_evasion[] | select(.confidence >= 0.5)]' ~/Documents/<target>/memory.json

# Last session's next steps
jq '.session_history[-1].next_steps[]' ~/Documents/<target>/memory.json
```

### During the Session

After every result that represents new knowledge:

1. **Successful technique** — add or update knowledge entry, increase confidence
2. **Failed technique** — update knowledge entry, decrease confidence
3. **New discovery** — add knowledge entry with initial confidence
4. **Target quirk observed** — add to target_quirk knowledge
5. **Tool configuration works** — record in tool_config knowledge
6. **WAF detected/bypassed** — record in waf_evasion knowledge

Write to the memory file immediately after each observation — same discipline as
workspace files. Never hold more than one observation in memory unwritten.

### At Session End

Append the session summary to `session_history` and update the `last_updated` timestamp.

## Memory Query Patterns

When deciding the next testing step, query memory for guidance:

```bash
# What bypasses have worked before?
jq '[.knowledge.bypass[] | select(.confidence >= 0.7)]' memory.json

# What should I avoid (repeatedly failed)?
jq '[.knowledge.strategy[] | select(.confidence < 0.3)]' memory.json

# What payloads worked for XSS?
jq '[.knowledge.payload[] | select(.category == "xss" and .confidence >= 0.5)]' memory.json

# What do I know about the target's session behavior?
jq '[.knowledge.target_quirk[] | select(.category == "session_management")]' memory.json

# What WAF evasion techniques work?
jq '[.knowledge.waf_evasion[] | select(.confidence >= 0.5)]' memory.json

# What tool configurations worked?
jq '[.knowledge.tool_config[] | select(.confidence >= 0.7)]' memory.json
```

## Memory Hygiene

- Remove entries with confidence < 0.1 after 5+ sessions (proven dead ends)
- Merge duplicate entries (same category + component + description)
- Keep `session_history` to last 20 entries (archive older ones)
- Validate that referenced scripts/paths still exist before trusting knowledge
- Update `confidence` scores based on recent session outcomes
- If a bypass stops working (failed 2+ sessions in a row), drop confidence by 0.2

## Integration with Other Prompt Files

- **DATAFLOW-VALIDATION.md** — Record validated dataflow paths as strategy knowledge
- **EXPLOIT-METHODOLOGY.md** — Record successful PoC approaches and chains as strategy knowledge
- **FINDINGS-PRIORITIZATION.md** — Use memory to inform severity adjudication
- **SEMGREP-GUIDE.md** — Record effective Semgrep rules as tool_config knowledge
- **CODEQL-GUIDE.md** — Record effective CodeQL queries as tool_config knowledge
