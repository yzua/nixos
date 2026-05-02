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
  "target": "com.example.app",
  "created": "2025-01-15",
  "last_updated": "2025-01-20",
  "sessions_completed": 5,
  "knowledge": {
    "strategy": [],
    "bypass": [],
    "payload": [],
    "target_quirk": [],
    "tool_config": [],
    "crash_pattern": [],
    "findings_db": []
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
  "target_component": "auth/login endpoint",
  "confidence": 0.9,
  "success_count": 1,
  "failure_count": 0,
  "last_seen": "2025-01-18T14:30:00Z",
  "details": "Sending JWT with alg:none and removing signature grants admin access"
}
```

Categories: `recon`, `auth_testing`, `injection`, `client_side`, `native_analysis`,
`config_review`, `crypto_analysis`, `network_analysis`

### Bypass Knowledge

Records specific bypass techniques that defeated security controls.

```json
{
  "type": "bypass",
  "category": "certificate_pinning",
  "description": "Frida hook on TrustManagerImpl.verifyChain() bypasses SSL pinning",
  "target_component": "com.example.app.security.SSLPinner",
  "confidence": 0.95,
  "success_count": 3,
  "failure_count": 0,
  "last_seen": "2025-01-19T10:15:00Z",
  "details": "Hook at com.example.app.security.SSLPinner.checkServerTrusted, return true",
  "script_path": "~/Documents/com.example.app/scripts/frida-ssl-bypass.js"
}
```

Categories: `certificate_pinning`, `root_detection`, `tamper_detection`,
`waf_bypass`, `rate_limit_bypass`, `auth_bypass`, `emulator_detection`

### Payload Knowledge

Records specific payload formats that triggered vulnerabilities.

```json
{
  "type": "payload",
  "category": "sql_injection",
  "description": "Time-based SQLi in content provider query parameter",
  "target_component": "content://com.example.app.provider/items",
  "confidence": 0.85,
  "success_count": 1,
  "failure_count": 0,
  "last_seen": "2025-01-18T16:45:00Z",
  "payload": "' OR (SELECT 1 FROM (SELECT SLEEP(5))a)--",
  "response_indicator": "5+ second delay"
}
```

Categories: `sql_injection`, `xss`, `command_injection`, `path_traversal`,
`intent_injection`, `deep_link`, `ssrf`, `prototype_pollution`

### Target Quirk Knowledge

Records target-specific behaviors that differ from standard expectations.

```json
{
  "type": "target_quirk",
  "category": "authentication",
  "description": "Session tokens valid for 24h but refresh token rotation fails silently",
  "target_component": "auth/refresh endpoint",
  "confidence": 1.0,
  "last_seen": "2025-01-17T09:00:00Z",
  "details": "Refresh endpoint returns 200 but same token — token reuse possible"
}
```

Categories: `authentication`, `session_management`, `api_behavior`,
`error_handling`, `rate_limiting`, `encoding`, `protocol`

### Tool Configuration Knowledge

Records tool configurations that produced useful results.

```json
{
  "type": "tool_config",
  "category": "frida",
  "description": "Frida spawn + attach mode with --no-pause for anti-debug bypass",
  "confidence": 0.8,
  "success_count": 2,
  "failure_count": 0,
  "last_seen": "2025-01-20T11:30:00Z",
  "config": "frida -U -f com.example.app --no-pause -l hook.js",
  "notes": "App detects attach mode; spawn mode with immediate resume avoids detection"
}
```

Categories: `frida`, `objection`, `mitmproxy`, `adb`, `semgrep`, `codeql`,
`nmap`, `burp`, `custom_script`

### Findings Database Knowledge

Records patterns about findings database usage across sessions.

```json
{
  "type": "findings_db",
  "category": "query_pattern",
  "description": "Useful query for finding chains across sessions",
  "query": "SELECT * FROM chains WHERE total_score >= 3.0",
  "confidence": 0.8,
  "success_count": 3,
  "failure_count": 0,
  "last_seen": "2026-01-15T14:30:00Z"
}
```

Categories: `schema_adaptation`, `query_pattern`, `correlation_pattern`, `data_quality`

### Crash Pattern Knowledge

Records crash patterns from native fuzzing sessions.

```json
{
  "type": "crash_pattern",
  "category": "heap_overflow",
  "description": "Heap overflow in protobuf parser at offset >256 bytes",
  "target_component": "libprotobuf_parser.so::parse_message",
  "confidence": 0.7,
  "success_count": 1,
  "failure_count": 0,
  "last_seen": "2025-01-19T15:00:00Z",
  "details": "Crash at parse_message+0x142, input length > 256 bytes triggers overflow",
  "crash_id": "id:000001,sig:11,src:000003"
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
  "goals": ["Test authentication bypass", "Scan content providers"],
  "findings": [
    "JWT alg:none bypass confirmed",
    "Content provider SQL injection confirmed"
  ],
  "strategies_tried": ["jwt_confusion", "content_provider_query"],
  "strategies_succeeded": ["jwt_confusion"],
  "strategies_failed": ["brute_force_login"],
  "blocked_items": ["Root detection bypass — multiple detection points"],
  "next_steps": ["Test IDOR on user endpoints", "Fuzz native parser"],
  "knowledge_added": 3,
  "knowledge_updated": 1
}
```

## Session Workflow

### At Session Start

Load context from existing memory:

```bash
# High-confidence strategies and bypasses
jq '[.knowledge | to_entries[] | .value[] | select(.confidence >= 0.7)]' ~/Documents/<target>/memory.json

# Failed strategies to avoid
jq '[.knowledge.strategy[] | select(.confidence < 0.3)]' ~/Documents/<target>/memory.json

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

# What payloads worked for injection testing?
jq '[.knowledge.payload[] | select(.category == "sql_injection" and .confidence >= 0.5)]' memory.json

# What do I know about the target's auth behavior?
jq '[.knowledge.target_quirk[] | select(.category == "authentication")]' memory.json

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
- **EXPLOIT-METHODOLOGY.md** — Record successful PoC approaches as strategy knowledge
- **NATIVE-FUZZING.md** — Record crash patterns and effective corpus strategies
- **FINDINGS-PRIORITIZATION.md** — Use memory to inform severity adjudication
- **SEMGREP-GUIDE.md** — Record effective Semgrep rules as tool_config knowledge
- **CODEQL-GUIDE.md** — Record effective CodeQL queries as tool_config knowledge
- **FINDINGS-DB.md** — Record effective query patterns and schema adaptations
- **DETECTION-PAIRING.md** — Record detection content that proved useful
- **EXPLOITATION-QUEUE.md** — Record exploitation strategies and outcomes
