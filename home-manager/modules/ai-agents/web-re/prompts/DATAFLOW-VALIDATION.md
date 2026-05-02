# Dataflow Validation for Web Findings

## Purpose

Most findings from dynamic testing (chrome-devtools, nuclei, sqlmap, dalfox) flag _potential_ vulnerabilities. A reflected parameter is only XSS if it lands in an executable context without proper encoding. An error message mentioning SQL is only SQLi if the query uses unparameterized input. This methodology separates real vulnerabilities from false positives before investing in PoC development.

Apply this framework to every finding that passes initial dynamic testing. The goal is a structured verdict: EXPLOITABLE, FALSE POSITIVE, or NEEDS TESTING.

## The 5-Step Validation Framework

### Step 1: Source Control Analysis

Classify the data source. Is it attacker-controlled?

**Attacker-controlled sources:**

- HTTP GET query parameters (`?user=admin`) — fully controlled
- HTTP POST body parameters (form data, JSON body) — fully controlled
- HTTP request headers (User-Agent, Referer, X-Forwarded-For, Cookie) — fully controlled by the requester
- URL path segments (`/api/users/123`) — fully controlled
- File upload contents and filenames — fully controlled
- WebSocket message payloads — fully controlled after connection
- Fragment identifiers (`#data`) — controlled but not sent to server (client-side only)

**Conditionally controlled:**

- Cookies (set by server, but client can modify arbitrary cookies)
- JWT tokens (client-controlled payload, server-controlled signature)
- LocalStorage/SessionStorage (set by same-origin JS, but XSS grants write access)
- Third-party API responses (controlled by the third party, not the attacker directly)

**Not attacker-controlled:**

- Server-side computed values (database queries, session state, server timestamps)
- Server-side configuration (environment variables, config files)
- Responses from internal microservices (not directly accessible)
- Server-generated CSRF tokens (unless the generation is predictable)

**Verdict for each source:** `ATTACKER_CONTROLLED` / `CONDITIONAL` / `NOT_CONTROLLED`

### Step 2: Sanitizer Effectiveness Analysis

For each sanitizer or encoding between source and sink, determine if it is effective or bypassable.

**Common web sanitizers and their effectiveness:**

| Sanitizer                                     | Effective For          | Bypass Method                                                                                                                               |
| --------------------------------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `htmlspecialchars($input, ENT_QUOTES)`        | HTML context XSS       | Not effective for JS context (`<script>val=USERINPUT</script>`), CSS context, URL context, or event handlers                                |
| `htmlspecialchars($input)` without ENT_QUOTES | HTML attribute XSS     | Single-quote attributes: `' onmouseover='alert(1)`                                                                                          |
| `mysqli_real_escape_string()`                 | MySQL SQL injection    | Not effective for other DB engines; not effective for numeric contexts or ORDER BY clauses                                                  |
| `PDO prepared statements`                     | SQL injection          | **Effective** — gold standard when used correctly                                                                                           |
| `parseInt(input)` / `Number(input)`           | Type coercion          | **Effective** if applied before concatenation; ineffective if applied after                                                                 |
| `input.trim()`                                | Whitespace removal     | Not a sanitizer for any injection type                                                                                                      |
| `encodeURIComponent(input)`                   | URL parameter encoding | **Effective** for URL parameters; not effective for HTML context or path traversal                                                          |
| `DOMPurify.sanitize(input)`                   | HTML XSS               | **Effective** for known configurations; check if configured to allow dangerous tags/attributes                                              |
| `Content-Security-Policy header`              | XSS execution          | Depends on policy strictness; `unsafe-inline` or `unsafe-eval` negates protection; check for bypass via JSONP endpoints, base-uri injection |
| `input.replace(/<script>/gi, "")`             | Naive XSS filter       | Bypassable: `<scr<script>ipt>`, `<ScRiPt>`, `<img src=x onerror=...>`, `<svg onload=...>`                                                   |
| `WAF rules`                                   | Various injections     | Bypassable with encoding (double-URL, Unicode, HTML entities), HTTP parameter pollution, chunked encoding, content-type switching           |
| `CORS configuration`                          | Cross-origin requests  | Check: is `Access-Control-Allow-Origin: *` used? Are credentials allowed with wildcard? Is the origin reflected without validation?         |
| `rate limiting`                               | Brute force            | Does not prevent the vulnerability itself; only slows exploitation                                                                          |

**For each sanitizer in the path, answer:**

1. What does it actually do (code-level or configuration-level)?
2. Is it appropriate for the injection context (HTML body, HTML attribute, JS, CSS, URL, SQL, OS command)?
3. Can it be bypassed? If so, how specifically?
4. Is it applied on ALL paths or just some code branches?

### Step 3: Reachability Analysis

Can an attacker actually trigger this code path?

**Endpoint reachability:**

- **Public endpoint** (no auth) — highly reachable from anyone
- **Authenticated endpoint** — reachable from any registered user
- **Admin-only endpoint** — reachable from admin accounts (check for IDOR to escalate)
- **Internal-only endpoint** (not exposed via reverse proxy / load balancer) — not directly reachable, but check for SSRF
- **API endpoint** — reachable from any origin if CORS is misconfigured

**Protection reachability:**

- No CSRF token — state-changing requests are reachable from any origin
- CSRF token present — protected against cross-origin but not same-origin (XSS bypasses this)
- Rate limiting present — slows exploitation but does not prevent the vulnerability
- IP allowlist — restricted to specific IPs; check for header spoofing (`X-Forwarded-For`)

**WAF reachability:**

- No WAF — payloads are not filtered
- WAF in blocking mode — standard payloads may be blocked; encoding bypasses may work
- WAF in detection-only mode — payloads go through but are logged
- Cloud WAF (Cloudflare, AWS WAF) — may have different rules for different endpoints

### Step 4: Exploitability Assessment

Given the source, sanitizer, and reachability analysis — is the full path exploitable?

**Construct the complete HTTP attack chain:**

```
Source (which param/header?) → Context (HTML/JS/SQL/command?) → Sanitizer (effective?) → Sink (what dangerous operation?) → Impact (what data/action?)
```

**Rate exploitability:**

- **TRIVIAL:** Attacker-controlled source, no effective sanitizer, public endpoint, no WAF, high impact
- **MODERATE:** Attacker-controlled source, bypassable sanitizer, authenticated endpoint, or requires specific content-type
- **COMPLEX:** Requires chaining (e.g., CSRF bypass + XSS + privilege escalation), WAF evasion, or specific application state
- **INFEASIBLE:** Source not attacker-controlled, effective sanitizer on all paths, or endpoint not reachable

### Step 5: Impact Analysis

If exploited, what does the attacker achieve?

Map to OWASP Top 10 2021:

| Category                         | Impact Examples                                                      |
| -------------------------------- | -------------------------------------------------------------------- |
| A01: Broken Access Control       | Access other users' data, admin functions without auth, IDOR         |
| A02: Cryptographic Failures      | Decrypt sensitive data, forge tokens, weak TLS                       |
| A03: Injection                   | SQLi: database access; XSS: account takeover; command injection: RCE |
| A04: Insecure Design             | Business logic flaws, race conditions, forced browsing               |
| A05: Security Misconfiguration   | Debug mode, default credentials, verbose errors, open cloud storage  |
| A06: Vulnerable Components       | Known CVEs in dependencies, supply chain compromise                  |
| A07: Auth Failures               | Credential stuffing, session fixation, weak password policy          |
| A08: Software/Data Integrity     | Insecure deserialization, CI/CD pipeline compromise                  |
| A09: Logging/Monitoring Failures | Attack goes undetected, no audit trail                               |
| A10: SSRF                        | Access internal services, cloud metadata, port scanning              |

## Validation Output Schema

For each validated finding, produce this structured output:

```markdown
### Finding: [title]

- **Source:** [which param/header/cookie, how controlled, verdict]
- **Sink:** [what dangerous operation — DB query, HTML render, system call, file access]
- **Path:** source → context → sanitizer → sink (with request/response evidence)
- **Sanitizers:** [list each, rating: EFFECTIVE / BYPASSABLE (method) / INEFFECTIVE]
- **Reachability:** [public? auth required? CORS? WAF? CSRF?]
- **Verdict:** EXPLOITABLE / FALSE POSITIVE / NEEDS TESTING
- **Confidence:** 0.0–1.0
- **Exploitability:** TRIVIAL / MODERATE / COMPLEX / INFEASIBLE
- **HTTP context:** [method, endpoint, content-type, required headers]
- **Attack payload concept:** [brief description of the working payload or bypass technique]
- **Impact:** [what attacker achieves, OWASP A-category]
- **CVSS estimate:** [vector string if enough data, or qualitative: critical/high/medium/low]
```

## Web-Specific Validation Patterns

### Reflected XSS

**Source:** HTTP parameter reflected in response body
**Validation:**

1. In what context is it reflected? HTML body, HTML attribute, JavaScript variable, CSS, URL?
2. Is there output encoding appropriate for that context?
3. Does CSP block inline scripts? Check for `unsafe-inline`, `unsafe-eval`, nonce/hash-based policies
4. Are there JSONP endpoints that could be used as script sources to bypass CSP?
5. Can you confirm execution with chrome-devtools `evaluate_script` or by observing a network request to your server?

**Dynamic proof:** Use chrome-devtools to navigate with the payload, take screenshot showing execution, capture network request proving exfiltration.

### Stored XSS

**Source:** User input stored server-side and displayed to other users
**Validation:**

1. Same context analysis as reflected XSS
2. Who can see the stored content? (All users, specific roles, admin only)
3. Is there input validation on storage or output encoding on display?
4. Can the stored payload survive editing/sanitization cycles?
5. Is the storage in a field that is typically displayed unencoded (e.g., username in a navbar)?

**Dynamic proof:** Store the payload, open a different session/browser context, verify execution.

### SQL Injection

**Source:** HTTP parameter used in database query
**Validation:**

1. Is the parameter used in string concatenation or interpolation for the query?
2. Are there prepared statements with bound parameters?
3. Which database engine? (MySQL, PostgreSQL, SQLite, MSSQL, Oracle — different bypass techniques)
4. Is the injection in WHERE, ORDER BY, LIMIT, INSERT, or another clause? (ORDER BY doesn't allow UNION)
5. Can you confirm with a time-based payload (`SLEEP()`, `pg_sleep()`, `WAITFOR DELAY`)?

**Dynamic proof:** Use sqlmap with `--level=3 --risk=2` and capture the confirmed payload, or manually demonstrate data extraction.

### IDOR (Insecure Direct Object Reference)

**Source:** Identifier in URL path, query param, or request body that controls which resource is accessed
**Validation:**

1. Does changing the ID return a different user's data?
2. Are IDs sequential (easily enumerable) or random (UUID/ULID)?
3. Is there server-side authorization checking that the current user owns the requested resource?
4. Can you access resources across accounts (use two test accounts)?
5. Does the IDOR work for both read and write operations?

**Dynamic proof:** Capture request with chrome-devtools, modify the ID, replay with curl or httpie from a different session, document the response diff.

### SSRF

**Source:** URL parameter that the server fetches or processes
**Validation:**

1. Does the server make an HTTP request based on user-supplied URL?
2. Can you reach internal services? (`http://localhost`, `http://127.0.0.1`, `http://10.0.0.1`)
3. Can you reach cloud metadata? (`http://169.254.169.254/latest/meta-data/` for AWS)
4. Can you use non-HTTP protocols? (`file://`, `gopher://`, `dict://`)
5. Is there URL validation that blocks internal IPs? Can it be bypassed with DNS rebinding, octal IPs, IPv6, or URL encoding?

**Dynamic proof:** Use your own server URL first, then try internal targets. Capture server response timing and content differences.

### JWT and Auth Token Issues

**Source:** JWT token or session token handling
**Validation:**

1. Is the JWT signed or using `alg: none`?
2. Is the signing key weak or predictable (try common wordlists)?
3. Can you modify the algorithm from RS256 to HS256 and use the public key as the HMAC secret?
4. Are sensitive claims (role, user_id) in the payload and trusted without server-side verification?
5. Is the token validated on every request or only on login?

**Dynamic proof:** Decode the JWT, modify claims, re-sign (or use `alg: none`), replay with modified token.

### CORS Misconfiguration

**Source:** Origin header reflected in `Access-Control-Allow-Origin` response header
**Validation:**

1. Does the server reflect any Origin in `Access-Control-Allow-Origin`?
2. Is `Access-Control-Allow-Credentials: true` also set? (This is the dangerous combination)
3. Are there restricted origins that are still allowed? (e.g., `*.example.com` subdomains)
4. Can null origin be used? (`Origin: null` from sandboxed iframes)
5. Does the CORS configuration apply to sensitive endpoints with data exfiltration potential?

**Dynamic proof:** Send request with `Origin: https://evil.com`, check response headers. If ACAO reflects evil.com with credentials, demonstrate data theft with a PoC HTML page.

## Integration with Workflow

- **After Phase 3 (Application Mapping):** When JS source or API schemas are discovered, apply the 5-step validation to suspected data flows visible in the source.
- **During Phase 6 (Vulnerability Testing):** Before writing a full PoC, validate each suspected vulnerability with the 5-step framework. Only invest in PoC development for EXPLOITABLE or NEEDS TESTING findings.
- **During Phase 9 (Confidence Review):** Update validation verdicts based on testing evidence. Upgrade NEEDS TESTING to EXPLOITABLE or downgrade to FALSE POSITIVE based on observed behavior.
- **During Phase 10 (Report and POC):** Include the structured validation output for each finding in the final report.
