# Web RE Workspace

This directory is the editable instruction and workflow source for web application
security testing on this machine.

The Markdown files here are injected into the `web-re` OpenCode agent. Keep
operational guidance here, not hardcoded in shell wrappers.

## Current Baseline

- Browser: Chrome with DevTools Protocol on port 9222
- Proxy: mitmproxy/mitmdump on port 8084 with custom CA
- Chrome DevTools MCP: primary interaction tool for all browser testing
- Reconnaissance: subfinder, amass, httpx, katana, whatweb
- Vulnerability scanning: nuclei, nikto, sqlmap, dalfox, zap
- Fuzzing: ffuf, arjun
- HTTP clients: curl, httpie, hurl, bruno, grpcurl
- Analysis: cyberchef, jq
- Host: x86_64 Linux

## Prompt Source Layout

- `AGENTS.md`: session contract, priorities, workflow rules, evidence templates
- `CODEQL-GUIDE.md`: CodeQL setup, database creation, and custom web queries
- `DATAFLOW-VALIDATION.md`: 5-step source-to-sink validation framework
- `EXPLOIT-METHODOLOGY.md`: structured PoC development with per-vuln strategies
- `EXPLOIT-VERIFICATION.md`: proof-of-exploitation levels, bypass exhaustion protocol, per-type evidence checklists
- `FINDINGS-PRIORITIZATION.md`: adversarial priority order and severity adjudication
- `SEMGREP-GUIDE.md`: Semgrep setup and custom web rules
- `SESSION-MEMORY.md`: persistent learning across sessions with confidence scoring
- `DETECTION-PAIRING.md`: mandatory detection content for confirmed findings
- `EXPLOITATION-QUEUE.md`: structured vuln-to-exploit handoff JSON schema
- `FINDINGS-DB.md`: SQLite findings database schema and CLI integration
- `STRATEGIC-INTEL.md`: backward taint analysis, advanced XSS/SSRF, structured auth/authz methodology
- `SESSION-MEMORY.md`: persistent learning across sessions with confidence scoring
- `TOOLS.md`: task-oriented command recipes and tool guidance
- `TROUBLESHOOTING.md`: symptom-driven failure recovery
- `WORKFLOW.md`: phased web testing workflow and pivot logic

Operator-owned scripts stay outside this prompt bundle:

- `scripts/ai/web-re/web-re.sh`: environment validation and tool helper
- `scripts/ai/web-re/workspace-init.sh`: target workspace initialization
- `scripts/ai/web-re/opencode-web-re.sh`: OpenCode session launcher

## Target Workspace Convention

All target-specific work goes in `~/Documents/{target-name}/`. This directory
persists across sessions and carries findings, notes, evidence, and PoC scripts
between agent sessions.

Initialize a new target workspace:

```bash
bash scripts/ai/web-re/workspace-init.sh init example.target.com
```

The workspace contains OWASP-aligned templates for findings (A01–A10), endpoints,
attack surface maps, tech stack inventory, and session history. See `AGENTS.md`
for the full workspace convention and rules.

## Fast Start

### 1. Verify the environment

```bash
bash scripts/ai/web-re/web-re.sh doctor
bash scripts/ai/web-re/web-re.sh status
```

### 2. Start Chrome with DevTools if needed

```bash
bash scripts/ai/web-re/web-re.sh start-chrome
```

### 3. Choose the right launcher

- `ocwre` — balanced general web testing
- `ocgptwre` — structured auth/API testing and deeper exploitation
- `ocgemwre` — fast reconnaissance and multi-model validation
- `oczenwre` — static-first analysis and cost-effective wide scanning

Examples:

```bash
ocwre "prepare the environment and start testing https://example.com"
ocgptwre "focus on auth bypass, IDOR, and API surface testing"
ocgemwre "run comprehensive recon and tech fingerprinting"
oczenwre "do endpoint discovery and summarize likely attack vectors"
```

Full assessment example:

```bash
ocwre "full assessment of https://example.target.com at ~/Documents/example-target: \
read the dir to learn context from previous sessions, then do \
complete recon + mapping + vuln testing, test all endpoints and \
auth flows, find vulnerabilities, document everything in the \
workspace, put all scripts/PoC there, spawn subagents for parallel work"
```

Available profile launchers:

- `ocwre` -> default `opencode` profile
- `ocglmwre` -> `opencode-glm`
- `ocgemwre` -> `opencode-gemini`
- `ocgptwre` -> `opencode-gpt`
- `ocorwre` -> `opencode-openrouter`
- `ocswre` -> `opencode-sonnet`
- `oczenwre` -> `opencode-zen`

Each launcher:

- starts Chrome with DevTools in the background via `scripts/ai/web-re/web-re.sh`
- writes startup logs to `~/Downloads/web-re-tools/`
- builds prompt context from every root-level Markdown file in this directory
- opens Ghostty running OpenCode on the `web-re` agent

The agent should still verify readiness with `status` before testing.

## Decision Guide

Start every target by answering these questions in order:

1. **Is the baseline environment healthy?** (Chrome, mitmproxy, tools)
2. **What is the target URL and defined scope?**
3. **What technology stack does the target use?**
4. **What endpoints and API surface are discoverable?**
5. **How does the application authenticate users?**
6. **Can traffic be intercepted and analyzed?**
7. **What vulnerability classes are most likely given the tech stack?**
8. **What is the next smallest proof step?**

If you cannot answer a question with evidence, stay in the current phase.

## Launcher Bias Guide

Use the launcher that best fits the current branch, then switch once evidence
points elsewhere:

- `oczenwre` -> cheapest reconnaissance and wide endpoint discovery
- `ocgptwre` -> structured auth, API, and exploitation work
- `ocgemwre` -> fast multi-angle scanning and cross-validation
- `ocwre` -> balanced default when the target is not yet classified

## Vulnerability-First Heuristics

When choosing what to investigate next, prefer this order:

1. can I reach another user's data or an admin function? (IDOR, broken access control)
2. can I inject content that gets rendered or executed? (XSS, injection)
3. can I bypass authentication or authorization? (auth flaws)
4. can I make the server fetch internal resources? (SSRF)
5. can I extract sensitive data from responses or errors? (information disclosure)
6. can I manipulate tokens, sessions, or cookies? (auth/session flaws)

## Manual Commands

Environment health:

```bash
bash scripts/ai/web-re/web-re.sh doctor
bash scripts/ai/web-re/web-re.sh start-chrome
bash scripts/ai/web-re/web-re.sh status
```

Reconnaissance:

```bash
subfinder -d example.com -silent | httpx -silent
amass enum -passive -d example.com
whatweb https://example.com
katana -u https://example.com -silent -jc
```

Vulnerability scanning:

```bash
nuclei -u https://example.com -t ~/nuclei-templates/
nikto -h https://example.com
dalfox url https://example.com/search?q=test
sqlmap -u "https://example.com/api/users?id=1" --batch
```

Fuzzing:

```bash
ffuf -u https://example.com/FUZZ -w /usr/share/seclists/Discovery/Web-Content/common.txt
arjun -u https://example.com/api/endpoint
```

Traffic analysis:

```bash
bash scripts/ai/web-re/web-re.sh mitm-start
bash scripts/ai/web-re/web-re.sh mitm-stop
```

Target workspace:

```bash
bash scripts/ai/web-re/workspace-init.sh init example.target.com
```

Findings database:

```bash
findings-web init ~/Documents/<target>
findings-web list-vulns ~/Documents/<target>
findings-web add-vuln ~/Documents/<target> FIND-001 "Title" High A01 open
findings-web list-chains ~/Documents/<target>
```

Tool audit:

```bash
web-re-doctor
```

TOTP testing:

```bash
generate-totp <base32-secret>
```
