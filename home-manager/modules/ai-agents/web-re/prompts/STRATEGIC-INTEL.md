# Strategic Intelligence and Advanced Analysis

## Purpose

Advanced analysis methodologies that go beyond finding individual vulnerabilities. This file covers: (1) producing strategic intelligence for exploitation phases, (2) backward taint analysis for systematic XSS/SSRF discovery, (3) advanced attack patterns, and (4) structured auth/authz testing with formal guard criteria. Adapted from Shannon's specialist methodologies (96.15% XBOW benchmark).

## Strategic Intelligence Section Pattern

When producing session reports or handoff notes, include a "Strategic Intelligence for Exploitation" section alongside findings. This section gives the next phase actionable intelligence, not just a list of vulnerabilities.

### Required Intelligence Items

1. **WAF Behavior Analysis**: What payloads were blocked? What encoding bypasses worked or failed? What rules are in place (e.g., blocks `<script>` but allows `<img>`)? Document for future bypass attempts.

2. **Confirmed Database Technology**: DBMS type and version from error messages, banner grabbing, or SQLi probing. Affects syntax for further exploitation (MySQL vs PostgreSQL vs SQLite vs MSSQL).

3. **Cookie Security Analysis**: For each session cookie, document: HttpOnly flag, Secure flag, SameSite attribute, expiration, path scope. Missing HttpOnly = XSS can steal it. Missing Secure = MITM can capture it. SameSite=None = CSRF vector.

4. **CSP Policy Analysis**: Parse the Content-Security-Policy header. Document: script-src directives, presence of `unsafe-inline`/`unsafe-eval`, nonce/hash-based policies, allowed CDN domains. Identify bypass vectors: JSONP endpoints on allowed domains, script gadgets in allowed libraries, base-uri injection, dangling markup injection.

5. **Session Token Format**: JWT structure (header claims, payload claims, algorithm), opaque token format, session ID format. Where stored (cookie, localStorage, sessionStorage). Affects which attacks are viable.

### Example Format

```markdown
## Strategic Intelligence for Exploitation

**WAF:** Cloudflare in blocking mode. Blocks `<script>` and `SELECT` keywords. Bypass: `<ScRiPt>` case variation works; `SeLeCT` does not. Try `<img src=x onerror=...>` and HTML encoding.

**Database:** SQLite 3.x confirmed via error messages (`SQLITE_ERROR`). UNION-based extraction viable; no `SLEEP()` function available (use `LIKE`-based blind if UNION fails).

**Cookies:** `sessionid` cookie lacks HttpOnly flag — vulnerable to XSS theft. Has Secure flag. SameSite=Lax — protects against cross-origin POST but not GET-based CSRF.

**CSP:** `script-src 'self' cdn.example.com; style-src 'unsafe-inline'`. Bypass: cdn.example.com hosts AngularJS 1.4.x — client-side template injection via `{{constructor.constructor('alert(1)')()}}` bypasses CSP.

**Tokens:** JWT with RS256 algorithm. Payload contains `role` claim trusted by server — test algorithm confusion (RS256→HS256 with public key).
```

## Secure by Design Documentation

Systematically record what was tested and confirmed safe. This prevents re-testing in future sessions and demonstrates coverage completeness.

### Format

| Source (Parameter/Endpoint)    | Defense Mechanism                                                                                  | Verdict                                                       |
| ------------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `username` on `/profile`       | HTML entity encoding via `htmlspecialchars($input, ENT_QUOTES)` applied before render              | SAFE — encoding matches HTML_BODY context                     |
| `redirect_url` on `/login`     | Strict URL allowlist validation against configured list of trusted domains                         | SAFE — no bypass via scheme variation, subdomain, or encoding |
| `user_id` on `/api/users/{id}` | Ownership check: `if (req.user.id !== resource.ownerId) return 403` at line 142 before data return | SAFE — server-side guard confirmed                            |
| `q` on `/api/search`           | Parameterized query with bound `?` parameter — no string concatenation                             | SAFE — prepared statement prevents SQLi                       |

### When to Document

- After Phase 6 vulnerability testing: record each parameter tested and confirmed safe
- When a dataflow validation trace terminates at an effective sanitizer
- When a code path is confirmed unreachable from attacker-controlled input

## Backward Taint Analysis for XSS

Traditional forward analysis (source → sink) misses complex stored XSS patterns. Backward analysis starts at sinks and traces toward sources.

### Sink Enumeration

List all XSS sinks in the application. Common sinks:

| Sink                                 | Context   | Risk                        |
| ------------------------------------ | --------- | --------------------------- |
| `innerHTML = data`                   | HTML_BODY | High — no encoding          |
| `element.textContent = data`         | HTML_BODY | Safe — text-only            |
| `document.write(data)`               | HTML_BODY | High — no encoding          |
| `element.setAttribute("href", data)` | URL_PARAM | High — javascript: scheme   |
| `eval(data)`                         | JS_EXEC   | Critical — arbitrary code   |
| `setTimeout(data, ...)`              | JS_EXEC   | High — evaluates string     |
| `script.src = data`                  | URL_PARAM | High — load external script |
| `element.style.cssText = data`       | CSS_VALUE | Medium — CSS injection      |

### Backward Trace Procedure

1. **Start at sink**: Identify the sink and its render context (HTML_BODY, HTML_ATTRIBUTE, JAVASCRIPT_STRING, URL_PARAM, CSS_VALUE).

2. **Trace backward**: Follow the data variable from the sink toward its origin.

3. **Early termination on valid sanitizer**: If you encounter a sanitizer, check TWO conditions:
   - **Context match**: Is this sanitizer correct for the sink's render context? (e.g., `htmlspecialchars()` is correct for HTML_BODY but NOT for JAVASCRIPT_STRING)
   - **No post-sanitization mutation**: Has any string concatenation, encoding, or transformation occurred BETWEEN this sanitizer and the sink? If yes, the sanitizer is invalidated.
   - If BOTH conditions pass → path is SAFE. Stop tracing this path.

4. **Path forking**: If a variable at the sink can come from multiple code paths (if/else branches, different functions), trace EACH path independently. Each is a separate finding or safe path.

5. **Database Read Checkpoint**: If the backward trace reaches a database read (e.g., `db.query("SELECT name FROM users WHERE id=$1")`) without finding a sanitizer, this is a **Stored XSS** finding. The data from the DB is assumed untrusted. Document the specific DB read operation and field.

6. **Source identification**: If the trace reaches user input (HTTP parameter, header, cookie) without a valid sanitizer, classify the XSS type:
   - **Reflected XSS**: Trace terminates at immediate user input (URL param, form field, header)
   - **Stored XSS**: Trace terminates at a database read
   - **DOM XSS**: Entire path is client-side only (no server round-trip)

## Advanced XSS Topics

### DOM Clobbering

Inject HTML elements with `id` or `name` attributes that overwrite JavaScript global variables:

```html
<!-- Overwrites window.config -->
<form id="config"><input name="apiUrl" value="https://evil.com/api" /></form>
<!-- If JS later reads config.apiUrl, it gets the attacker-controlled value -->
```

Test: look for JS that reads `window.X` or global variables that could be shadowed by injected HTML.

### Mutation XSS (mXSS)

The browser's HTML parser may "correct" malformed HTML, creating new injection vectors:

```html
<!-- Browser may parse this into an executable context -->
<noscript><p title="</noscript><img src=x onerror=alert(1)>"></p></noscript>
```

Test: when standard XSS payloads are sanitized, try malformed HTML that triggers parser "corrections." Particularly effective against DOMPurify with certain configurations.

### Server-Side Template Injection (SSTI)

If the application uses templating engines (Jinja2, Handlebars, Twig, Freemarker), inject template syntax:

```
{{ 7*7 }}          → look for "49" in response (Jinja2, Twig)
${7*7}             → look for "49" in response (Freemarker, Velocity)
<%= 7*7 %>         → look for "49" in response (ERB)
#{7*7}             → look for "49" in response (Thymeleaf)
```

Test: inject template expressions in every input field. If arithmetic is evaluated, escalation to RCE is often possible depending on the engine.

### JSONP Callback XSS

If the application has JSONP endpoints (`/api/data?callback=handlerFunction`):

```html
<script src="https://target.com/api/data?callback=alert"></script>
<!-- Executes: alert({"user":"data"}) -->
```

Test: check if `callback` parameter allows arbitrary function names, special characters, or direct JavaScript injection. JSONP endpoints bypass same-origin policy and can be used for CSP bypass.

## XSS Render Context Taxonomy

The correct defense depends on where the data lands in the DOM. A sanitizer effective in one context is ineffective in another.

| Render Context    | Required Defense                        | Common Mistake                                                                                                      |
| ----------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| HTML_BODY         | HTML entity encoding (`<` → `&lt;`)     | Using URL encoding in HTML context                                                                                  |
| HTML_ATTRIBUTE    | Attribute encoding (quote escaping)     | Using HTML entity encoding but missing quote context                                                                |
| JAVASCRIPT_STRING | JavaScript string escaping (`'` → `\'`) | Using HTML entity encoding in JS context (`var x='&lt;script&gt;...'` — browser doesn't execute tags in JS strings) |
| URL_PARAM         | URL encoding (`encodeURIComponent()`)   | Using HTML entity encoding in URL context                                                                           |
| CSS_VALUE         | CSS hex encoding                        | Using HTML entity encoding in CSS context                                                                           |

**Key rule**: `htmlspecialchars()` is effective ONLY for HTML_BODY and HTML_ATTRIBUTE contexts. It does NOT prevent XSS in JAVASCRIPT_STRING, URL_PARAM, or CSS_VALUE contexts.

## SSRF Type-Specific Exploitation

Not all SSRF is the same. Each type requires a different validation and exploitation strategy.

### Classic SSRF (Response Returned)

The server fetches the URL and returns the response content to you.

**Validation**: Supply a URL you control (e.g., `https://your-server.com/ping`). Check your server logs for the incoming request. If you see it, SSRF confirmed.

**Exploitation**: Replace your URL with internal targets: `http://127.0.0.1:8080/admin`, `http://10.0.0.1:3000/api/internal`.

### Blind SSRF (No Response)

The server makes the request but does not return the response content.

**Validation**: Use OOB (out-of-band) confirmation. Point to your server or Interactsh/Burp Collaborator. Observe DNS lookup or HTTP request from the target server's IP.

**Exploitation**: Port scanning via timing or error differences. Cloud metadata via response timing.

### Semi-Blind SSRF (Error/Timing Signals)

No direct response, but errors or timing differences reveal information.

**Validation**: Compare responses for:

- Known dead IP (`http://10.255.255.1/`) → timeout
- Known fast host (`http://example.com/`) → quick response
- Internal host (`http://127.0.0.1:22/`) → connection refused vs timeout

Different responses = SSRF confirmed.

**Exploitation**: Map internal services by probing known ports and observing error messages or timing patterns.

### Stored SSRF

The URL is stored (e.g., webhook URL, profile image URL) and fetched later by the server.

**Validation**: Plant a URL pointing to your server in the stored field. Wait for the server to fetch it (may require triggering an event like a webhook fire).

**Exploitation**: Update the stored URL to point to internal services. The server fetches it on the next trigger.

## 9-Step Ordered Auth Testing

Apply these steps in order during Phase 5 (Authentication Testing). Each step builds on findings from previous steps.

### Step 1: Transport & Caching

- Is the login endpoint HTTPS-only? Does it redirect HTTP → HTTPS?
- Is HSTS header present with adequate max-age?
- Are authentication-related responses marked `Cache-Control: no-store`?
- Are credentials sent in URL parameters (logged in proxy/access logs)?

### Step 2: Rate Limiting & Abuse Defenses

- How many failed login attempts before lockout or CAPTCHA?
- Is rate limiting per-IP, per-account, or per-session?
- Can rate limiting be bypassed via `X-Forwarded-For` header rotation?
- Is there account lockout? Does lockout enable enumeration (locked = account exists)?

### Step 3: Session Management

- Session cookie flags: HttpOnly? Secure? SameSite (Strict/Lax/None)?
- Session ID entropy: is it predictable (sequential, timestamp-based)?
- Session rotation: does the session ID change after login?
- Session timeout: absolute timeout? Idle timeout? Both?

### Step 4: Token Properties

- JWT or opaque token? If JWT: algorithm, claims, signing key strength
- Token lifetime: access token TTL, refresh token TTL
- Token storage: cookie, localStorage, sessionStorage — affects XSS impact
- Token binding: is token bound to IP, user-agent, or other fingerprint?

### Step 5: Session Fixation

- Does the session ID change between pre-login and post-login states?
- Can an attacker set a session ID before the victim logs in?
- Test: set a known cookie value, then log in. If the cookie doesn't change, session fixation is possible.

### Step 6: Password & Account Policy

- Password complexity requirements (length, character classes)
- Password hashing algorithm (bcrypt, scrypt, argon2 vs MD5, SHA-1)
- Default credentials for new accounts
- MFA availability and enforcement
- Password change: does it require current password?

### Step 7: Login & Signup Responses

- Error messages: specific ("user not found" vs "wrong password") enables enumeration
- Response timing: does "user not found" respond faster than "wrong password"?
- Information leakage in responses (internal IDs, email addresses, role names)

### Step 8: Recovery & Logout

- Password reset: single-use tokens? Token expiration? Token entropy?
- Reset token delivery: email? SMS? In-band (API response)?
- Logout: server-side session invalidation or just client-side cookie removal?
- Token revocation: can previously issued tokens be revoked?

### Step 9: SSO & OAuth

- **nOAuth check**: does the app use the mutable `email` claim or immutable `sub` claim for user identification? If `email`: attacker changes their OAuth provider email to victim's email → account takeover.
- OAuth `state` parameter: present and validated? (Prevents CSRF)
- OAuth `nonce` parameter: present? (Prevents replay)
- Redirect URI: strict allowlist or pattern matching? (Prevents open redirect token theft)
- PKCE: implemented for public clients (SPAs, mobile)?
- Token endpoint: does it require client authentication?

## 3-Category Authorization Testing with Formal Guard Criteria

Authorization flaws fall into three categories, each with specific guard requirements. During Phase 6.5, test each category systematically.

### Horizontal (Ownership Bypass)

Can user A access user B's data at the same privilege level?

**Sufficient guard criteria**: The application must verify `requester.id == resource.owner_id` at the point of data access, in server-side code. This check must happen BEFORE the data is returned or modified.

**What does NOT count as a guard**:

- UI hiding the data (inspect API directly)
- The ID being hard to guess (UUIDs reduce probability but are not authorization)
- Client-side filtering (server returns all data, client shows only "yours")

**Test with two accounts**: Account A tries to access Account B's resources by changing IDs in API requests. Document the response diff.

### Vertical (Role/Capability Escalation)

Can a lower-privilege user access higher-privilege functions?

**Sufficient guard criteria**: The application must check `requester.role ∈ required_roles` BEFORE executing the privileged operation. The role check must be server-side and on every code path to the operation.

**What does NOT count as a guard**:

- UI hiding admin links (try the admin URL directly)
- The endpoint not being in the navigation (fuzz for hidden endpoints)
- Role stored in JWT without server-side verification (client can modify JWT)

**Test with role escalation**: Use a regular user session to access admin endpoints. Try HTTP method switching (POST blocked but PUT works). Try adding `role=admin` to request body.

### Context/Workflow (State Validation)

Can a user skip required steps or bypass state transitions?

**Sufficient guard criteria**: The application must verify `prior_step.completed == true` BEFORE allowing the next step. State validation must be server-side and tied to the specific user/session.

**What does NOT count as a guard**:

- UI disabling the "Next" button (call the API directly)
- Client-side JavaScript validation (bypass with curl)
- Session storage of step completion without server-side verification

**Test with workflow bypass**: Identify multi-step processes (checkout, onboarding, password reset). Try accessing step N directly without completing steps 1 through N-1. Try setting state parameters directly.

### Guard Evidence Tracking

For each authorization test, document:

- **Endpoint tested**: method + path
- **Role context used**: what account/role made the request
- **Guard found**: what authorization check exists (or "none found")
- **Guard location**: file:line if visible in source, or "server-side" / "client-side only"
- **Guard timing**: does the check happen BEFORE or AFTER the side effect?
- **Verdict**: SUFFICIENT / INSUFFICIENT / MISSING

**Key rules**: Guards after the side effect do not count. UI-only checks do not count. Client-side checks do not count.

## Integration with Workflow

- **Phase 5 (Auth Testing)**: Apply the 9-step auth methodology and nOAuth check. Record findings in the Strategic Intelligence section.
- **Phase 5.5 (Dataflow Validation)**: Use backward taint analysis for XSS sink enumeration alongside forward source-to-sink tracing.
- **Phase 6 (Vulnerability Testing)**: Apply SSRF type-specific exploitation. Use XSS render context taxonomy to match payloads to contexts.
- **Phase 6.5 (Business Logic Testing)**: Apply 3-category authz testing with formal guard criteria. Document guard evidence.
- **Phase 9 (Confidence Review)**: Include Strategic Intelligence section in session report. Record "Secure by Design" findings.
- **Phase 10 (Report and POC)**: Include Strategic Intelligence section in final deliverable. This gives the next session actionable context.
