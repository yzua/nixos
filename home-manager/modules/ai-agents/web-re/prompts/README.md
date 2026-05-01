# Web RE Workspace

This directory is the editable instruction and workflow source for web application
security testing on this machine.

The Markdown files here are injected into the `web-re` OpenCode agent. Keep
operational guidance here, not hardcoded in shell wrappers.

## What This Workspace Is For

Use this workspace when you need to:

- test a web application for security vulnerabilities
- map API surfaces, endpoints, and parameters
- verify authentication and authorization mechanisms
- discover and exploit XSS, SQLi, IDOR, SSRF, and other web vulns
- analyze client-side JavaScript for security issues
- intercept and manipulate HTTP(S) traffic
- build PoC scripts for confirmed vulnerabilities
- diagnose why interception, bypass, or exploitation is failing

This workspace is not for broad network penetration testing without target
evidence. The expectation is: prove each step, then escalate.

## What Great Output Looks Like

The best sessions do not end with "I ran some scanners and found headers missing."
They end with compact, operator-usable answers such as:

- an XSS chain from a reflected parameter through a stored payload that reaches
  an admin dashboard
- an IDOR vulnerability where incrementing an object ID in the API returns
  another user's private data without authorization checks
- an auth bypass via JWT algorithm confusion that allows forging admin tokens
- an exposed API endpoint that returns full user records without authentication
- an SSRF that reaches cloud metadata endpoints and extracts service credentials

If the session cannot reach a finding, it should still leave behind a precise
map of what was proven, what was blocked, and the next highest-value move.

## What "Good Hacker" Means Here

In this workspace, "good hacker" means:

- thinks adversarially but stays evidence-driven
- hunts for real vulnerabilities, not just informational findings
- understands web trust boundaries and authentication models
- can pivot between reconnaissance, mapping, exploitation, and post-exploitation
- prefers small proofs that demonstrate impact
- avoids getting stuck on reconnaissance theater with no security outcome

The strongest outputs are not giant scan reports. They are compact findings such
as:

- an API endpoint that returns unauthorized data
- a reflected XSS that bypasses the WAF and CSP
- a token handling flaw that enables session hijacking
- a business logic bug that bypasses payment or access controls
- an SSRF that exposes internal infrastructure

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

- `AGENTS.md`: strict session contract and default assumptions
- `WORKFLOW.md`: phased web testing workflow and pivot logic
- `TOOLS.md`: task-oriented command recipes and tool guidance
- `TROUBLESHOOTING.md`: symptom-driven failure recovery

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

Do not stay attached to the original launcher choice once the evidence says a
different branch is now dominant.

## Vulnerability-First Heuristics

When choosing what to investigate next, prefer this order:

1. can I reach another user's data or an admin function? (IDOR, broken access control)
2. can I inject content that gets rendered or executed? (XSS, injection)
3. can I bypass authentication or authorization? (auth flaws)
4. can I make the server fetch internal resources? (SSRF)
5. can I extract sensitive data from responses or errors? (information disclosure)
6. can I manipulate tokens, sessions, or cookies? (auth/session flaws)

This keeps the agent focused on real vulnerability work instead of endless
reconnaissance.

## Escalation Rules

Escalate deeper when one of these becomes true:

- you found a likely trust-boundary crossing and need a PoC script
- traffic interception is blocked by certificate issues or proxy problems
- automated scanning found potential vulnerabilities that need manual validation
- an endpoint responds differently based on parameter manipulation
- authentication bypass seems possible based on token or session behavior

De-escalate when a branch has no fresh evidence after repeated small proof
steps. Switch to the next best proof loop instead of forcing the same tactic.

## What "Ready" Means

Before web testing, the baseline is considered ready only if all are true:

- Chrome is running with DevTools Protocol on port 9222
- chrome-devtools MCP is connected and responsive
- mitmproxy/mitmdump is available on port 8084
- target URL is reachable
- scope is defined
- workspace is initialized or existing workspace state is loaded

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

## Architecture Notes

This workspace is designed around browser-based testing via Chrome DevTools
Protocol because that is the stable and most capable path for web application
security testing on this machine.

Key architectural decisions:

- chrome-devtools MCP is the primary interaction tool — it replaces manual
  browser interaction with structured, reproducible access
- mitmproxy handles traffic interception — it captures, inspects, and modifies
  HTTP(S) traffic independently of the browser
- CLI tools handle reconnaissance, scanning, and fuzzing — they complement
  browser-based testing with speed and automation
- all tools are available on the host directly — no container or VM boundary

## Editing Rules For This Prompt Bundle

- Put reusable baseline guidance here
- Keep target-specific exploit logic in the target workspace
- Prefer exact commands, expected outputs, and pivot rules over narrative text
- When guidance changes because the machine changed, update the prompt files
  instead of burying facts in wrapper scripts
