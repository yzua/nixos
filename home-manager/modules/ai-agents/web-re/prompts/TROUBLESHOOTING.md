# Web RE Troubleshooting

Use this file as a symptom -> proof -> next action guide. Do not apply fixes
blindly. Confirm the failure mode first, then choose the smallest recovery step.

## Chrome Won't Connect to DevTools MCP

Prove the current state:

```bash
bash scripts/ai/web-re/web-re.sh status
curl -s http://localhost:9222/json/version
```

If Chrome is not running:

```bash
bash scripts/ai/web-re/web-re.sh start-chrome
```

If Chrome is running but DevTools port is not accessible:

```bash
ss -ltnH '( sport = :9222 )'
ps aux | grep chrome | grep remote-debugging
```

Likely causes:

- Chrome started without `--remote-debugging-port=9222`
- another process bound to port 9222
- Chrome crashed and left a stale lock file

Recovery:

```bash
# Kill stale Chrome processes
pkill -f 'chrome.*remote-debugging'
sleep 2
bash scripts/ai/web-re/web-re.sh start-chrome
curl -s http://localhost:9222/json/version
```

## Target URL Unreachable

Prove the failure:

```bash
curl -v https://example.target.com 2>&1 | head -30
ping -c 3 example.target.com
nmap -p 80,443 example.target.com
```

Interpretation:

- DNS resolution fails -> domain does not exist, DNS issue, or typo
- TCP connection fails -> host down, firewall blocking, or wrong IP
- TLS handshake fails -> certificate issue, TLS version mismatch, or MITM
- HTTP error response -> server is up but application has issues

Next actions:

- verify the URL is correct
- check DNS: `dig example.target.com`, `nslookup example.target.com`
- try HTTP instead of HTTPS
- check if the target is behind a CDN that blocks direct access
- check if the target requires a specific Host header

## mitmproxy Not Seeing Traffic

### Step 1: verify mitmproxy is running

```bash
bash scripts/ai/web-re/web-re.sh mitm-stop
bash scripts/ai/web-re/web-re.sh mitm-start
ss -ltnH '( sport = :8084 )'
tmux capture-pane -t web-re:mitm -p -S -80
```

### Step 2: verify proxy configuration

```bash
# Check if browser is configured to use the proxy
# Chrome should be started with --proxy-server=http://127.0.0.1:8084
ps aux | grep chrome | grep proxy
```

If proxy is not configured:

```bash
bash scripts/ai/web-re/web-re.sh start-chrome --proxy
```

### Step 3: verify CA trust

```bash
# Check if mitmproxy CA is trusted
ls -la ~/Downloads/web-re-tools/custom-ca/
openssl x509 -in ~/Downloads/web-re-tools/custom-ca/mitmproxy-ca-cert.pem -text -noout | head -20
```

### Step 4: test with a simple request

```bash
curl -x http://127.0.0.1:8084 -k https://example.target.com -I
tmux capture-pane -t web-re:mitm -p -S -40
```

If `curl` through proxy works but browser does not:

- browser proxy configuration is incorrect
- browser uses its own certificate store (not system)
- browser has proxy bypass rules for the target domain

## SSL/TLS Handshake Failures

Prove the failure:

```bash
curl -v https://example.target.com 2>&1 | grep -E 'SSL|TLS|certificate|handshake'
openssl s_client -connect example.target.com:443 -servername example.target.com </dev/null 2>&1 | head -30
```

Common causes:

- expired or invalid server certificate
- certificate chain incomplete
- TLS version mismatch (server requires TLS 1.3, client offers 1.2)
- SNI required but not sent
- HSTS pinning in browser

Next actions:

- check certificate validity: `openssl s_client -connect example.target.com:443`
- check supported TLS versions: `nmap --script ssl-enum-ciphers -p 443 example.target.com`
- try with explicit TLS version: `curl --tlsv1.2 https://example.target.com`
- if behind mitmproxy, check CA trust and mitmproxy logs

## WAF Blocking Requests

Symptoms:

- requests return 403 with WAF-specific error pages
- responses contain keywords like "blocked", "forbidden", "firewall"
- certain payloads trigger blocks while normal requests work

Prove the WAF:

```bash
# Basic WAF detection
whatweb https://example.target.com | grep -i waf
nmap --script http-waf-detect -p 443 example.target.com

# Test what triggers blocks
curl -s "https://example.target.com/search?q=test" -w "\n%{http_code}\n"
curl -s "https://example.target.com/search?q=<script>" -w "\n%{http_code}\n"
curl -s "https://example.target.com/search?q=' OR 1=1--" -w "\n%{http_code}\n"
```

Bypass techniques to try:

- URL encoding: `%3Cscript%3E` instead of `<script>`
- Double URL encoding: `%253Cscript%253E`
- HTML entity encoding: `&#60;script&#62;`
- Case variation: `<ScRiPt>`
- Null bytes: `%00<script>`
- Unicode normalization: `<script>`
- Content-Type switching: JSON, XML, multipart
- HTTP parameter pollution: duplicate parameters
- Split payloads across multiple parameters

Do not spend excessive time on WAF bypass without evidence that bypassing it
leads to a real vulnerability.

## Chrome DevTools Snapshot Empty or Stale

Prove the state:

```
navigate_page to https://example.target.com
take_snapshot
```

If the snapshot is empty or does not match the visible page:

- the page may have loaded via JavaScript after the snapshot was taken
- the page may use shadow DOM that the snapshot does not traverse
- the page may be a SPA that has not finished rendering

Recovery:

```
# Wait and re-snapshot
evaluate_script "document.readyState"
take_snapshot

# Force wait for page load
evaluate_script "await new Promise(r => setTimeout(r, 3000))"
take_snapshot
```

## JavaScript Injection Blocked by CSP

Symptoms:

- `evaluate_script` calls return CSP violation errors
- `list_console_messages` shows Content Security Policy violations
- injected scripts do not execute

Prove the CSP:

```
evaluate_script "document.querySelector('meta[http-equiv=Content-Security-Policy]')?.content"
list_console_messages
```

Also check headers:

```bash
curl -sI https://example.target.com | grep -i "content-security-policy"
```

Workarounds:

- use chrome-devtools `evaluate_script` — it runs in the page context and
  may bypass some CSP restrictions since it is injected by DevTools
- test if the CSP has `unsafe-inline` or `unsafe-eval` — these weaken it
- check if the CSP allows `script-src` from a domain you control
- look for CSP bypass techniques specific to the framework

## Network Requests Not Appearing in DevTools

Symptoms:

- you navigate to a page and `list_network_requests` returns empty or stale
- you know the page makes API calls but DevTools does not show them

Prove the state:

```
navigate_page to https://example.target.com
evaluate_script "fetch('/api/test').then(r => r.text()).then(t => console.log(t))"
list_network_requests
list_console_messages
```

If requests still do not appear:

- the requests may have been made before DevTools started capturing
- the page may use a Service Worker that intercepts requests
- WebSocket connections may not appear in the standard network list

Recovery:

```
# Reload page to capture from the start
navigate_page to https://example.target.com
list_network_requests

# Check for Service Workers
evaluate_script "navigator.serviceWorker.controller"
evaluate_script "navigator.serviceWorker.getRegistrations().then(r => console.log(r))"

# Check for WebSocket connections
evaluate_script "performance.getEntriesByType('resource').filter(r => r.name.includes('ws')).map(r => r.name)"
```

## Authentication Token Expired During Testing

Symptoms:

- API calls that previously worked now return 401
- chrome-devtools shows login redirect instead of expected page
- error messages about invalid or expired tokens

Prove the state:

```bash
curl -s -H "Authorization: Bearer $TOKEN" "https://example.target.com/api/me" -w "\n%{http_code}\n"
```

Recovery:

```
# Re-authenticate via chrome-devtools
navigate_page to https://example.target.com/login
take_snapshot
fill username input with credentials
fill password input with credentials
click submit
take_snapshot — confirm successful login
evaluate_script "document.cookie" — capture new session cookies

# If using JWT, decode and check expiration
python3 -c "import jwt,time,sys; t=sys.argv[1]; d=jwt.decode(t,options={'verify_signature':False}); print('exp:', d.get('exp'), 'now:', int(time.time()))" "$TOKEN"
```

Next actions:

- note the token lifetime and plan testing within that window
- write automation to re-authenticate when tokens expire
- check if refresh tokens are available

## Console Shows Nothing Despite Interaction

Symptoms:

- you click elements or navigate but `list_console_messages` returns empty
- you expect JavaScript errors or log output but see nothing

Prove the state:

```
evaluate_script "console.log('test-output-12345')"
list_console_messages
```

If the test message does not appear:

- console capture may not be active
- the page may have overridden console methods
- DevTools connection may have a timing issue

Recovery:

```
# Force a console message and verify
evaluate_script "console.log('PROBE', Date.now())"
list_console_messages

# Check if console was overridden
evaluate_script "console.log.toString()"
evaluate_script "console.error.toString()"

# Restore if overridden
evaluate_script "console.log = console.log.bind(console)"
```

## Target Has Rate Limiting or IP Blocking

Symptoms:

- repeated requests return 429 (Too Many Requests)
- responses include `Retry-After` headers
- after many requests, all requests return 403
- `curl` times out or connection refused

Prove the rate limit:

```bash
# Test rate limit threshold
for i in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://example.target.com/api/endpoint")
  echo "Request $i: $code"
  if [ "$code" = "429" ] || [ "$code" = "403" ]; then
    echo "Rate limited after $i requests"
    break
  fi
done

# Check rate limit headers
curl -sI "https://example.target.com/api/endpoint" | grep -i "rate\|retry\|x-ratelimit"
```

Workarounds:

- add delays between requests: `sleep 1` between API calls
- use different parameter values each time to avoid pattern matching
- spread requests across different endpoints
- change User-Agent and other identifying headers
- use `curl-impersonate` to change TLS fingerprint
- write scripts that respect rate limits with exponential backoff
- focus on targeted testing rather than broad brute-force

Do not bypass rate limiting for denial-of-service testing — only bypass to
complete security testing within authorized scope.

## Chrome DevTools MCP Connection Lost

Symptoms:

- chrome-devtools MCP commands return errors or time out
- the MCP server reports connection failures

Prove the state:

```bash
curl -s http://localhost:9222/json/version
ps aux | grep chrome | grep remote-debugging
```

Recovery:

```bash
# Restart Chrome
pkill -f 'chrome.*remote-debugging'
sleep 2
bash scripts/ai/web-re/web-re.sh start-chrome
curl -s http://localhost:9222/json/version
```

If Chrome keeps crashing:

- check available memory: `free -h`
- check Chrome crash logs: `~/.config/google-chrome/Crash Reports/`
- try with fewer tabs or extensions
- try headless mode: `bash scripts/ai/web-re/web-re.sh start-chrome --headless`

## nuclei Scan Returns No Results

Symptoms:

- nuclei runs but finds nothing
- scan completes very quickly without testing templates

Prove the setup:

```bash
# Verify nuclei and templates
nuclei --version
ls ~/nuclei-templates/ | head -20
nuclei -tl | wc -l

# Run with verbose output
nuclei -u https://example.target.com -t ~/nuclei-templates/ -v -o /tmp/nuclei-verbose.txt 2>&1 | head -50
```

Common causes:

- templates not updated: `nuclei -update-templates`
- target not reachable from nuclei
- WAF blocking nuclei requests
- wrong template path

## SQLMap Not Detecting Injection

Symptoms:

- you suspect SQL injection but sqlmap reports all parameters are not injectable
- manual testing shows odd behavior but sqlmap does not confirm it

Prove the injection point:

```bash
# Manual test first
curl -s "https://example.target.com/api/users?id=1" | md5sum
curl -s "https://example.target.com/api/users?id=1'" | md5sum
curl -s "https://example.target.com/api/users?id=1 AND 1=1" | md5sum
curl -s "https://example.target.com/api/users?id=1 AND 1=2" | md5sum

# Try different sqlmap options
sqlmap -u "https://example.target.com/api/users?id=1" --batch --level=5 --risk=3
sqlmap -u "https://example.target.com/api/users?id=1" --batch --technique=BEUSTQ
sqlmap -u "https://example.target.com/api/users?id=1" --batch --tamper=space2comment,between
```

If WAF is blocking:

```bash
sqlmap -u "https://example.target.com/api/users?id=1" --batch --random-agent --tamper=space2comment
```

## Generic Ownership Boundary

This baseline owns:

- Chrome DevTools setup and connectivity
- mitmproxy setup and CA configuration
- tool availability and version verification
- tmux session management

Target-specific exploit scripts, PoC tools, custom payloads, and attack
automation should live in target-specific workspaces rather than in this generic
bundle.
