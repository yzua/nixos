# Dataflow Validation for Android Findings

## Purpose

Most findings from static triage (jadx output, manifest analysis) are _potential_ vulnerabilities, not proven ones. A string concatenation in a SQL query is only dangerous if the string is attacker-controlled and not effectively sanitized. This methodology separates real vulnerabilities from false positives before investing in PoC development.

Apply this framework to every finding that passes initial grep-based triage. The goal is a structured verdict: EXPLOITABLE, FALSE POSITIVE, or NEEDS TESTING.

## The 5-Step Validation Framework

### Step 1: Source Control Analysis

Classify the data source. Is it attacker-controlled?

**Attacker-controlled sources:**

- Intent extras from exported activities, services, or receivers (any third-party app can send them)
- Deep link URI parameters (any browser or app can trigger)
- Content provider query parameters (if the provider is exported without signature permission)
- Bundle extras passed to exported components
- User input fields in WebView forms (if JS bridge exposes them)
- NFC tag data (if the app reads NDEF messages)
- Clipboard data (if the app reads it)

**Requires access first:**

- SharedPreferences values (unless another app can write them via exported provider or world-readable file)
- Internal database content (unless an exported component writes to it first)
- Environment variables or system properties (rarely attacker-controlled on non-rooted devices)
- Account data from AccountManager (requires app-specific auth)

**Internal only / likely false positive:**

- Hardcoded strings or constants in code
- Internally computed values (loop counters, timestamps)
- Values written and read only within the same app with no external input path
- Build config values that are compile-time constants

**Verdict for each source:** `ATTACKER_CONTROLLED` / `REQUIRES_ACCESS` / `INTERNAL_ONLY`

### Step 2: Sanitizer Effectiveness Analysis

For each sanitizer or validation between source and sink, determine if it is effective or bypassable.

**Common Android sanitizers and their effectiveness:**

| Sanitizer                                         | Effective For        | Bypass Method                                                                                                         |
| ------------------------------------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `input.replace("'", "''")`                        | Simple SQLi chars    | Double-quote identifiers, UNION with no quotes                                                                        |
| `input.replace("<", "&lt;")`                      | Basic HTML chars     | JS context (`<script>` not needed), event handlers, CSS                                                               |
| `URLDecoder.decode(input)`                        | URL encoding         | Double-encoding (`%2527`), mixed encoding                                                                             |
| `input.trim()`                                    | Whitespace           | Not a sanitizer for any injection type                                                                                |
| `Integer.parseInt(input)`                         | Type coercion        | Effective IF exception is caught and value is used; fails if used after string concatenation                          |
| `input.matches(regex)`                            | Pattern matching     | Depends on regex correctness; `.*` is not a sanitizer; complex regexes may have ReDoS but rarely block injection      |
| `parameterized queries` (bound `?` params)        | SQL injection        | **Effective** — the gold standard for SQL defense                                                                     |
| `Html.encodeHtml(input)`                          | HTML output encoding | **Effective** for HTML context; does NOT help for JS/CSS/URL contexts                                                 |
| `ContentProvider.query()` with selection args     | SQL in providers     | **Effective** if selection args are used correctly; vulnerable if string concatenation is used instead                |
| `File.getCanonicalPath()` + prefix check          | Path traversal       | **Effective** if checked after canonicalization and before use; bypassable if checked before canonicalization         |
| `WebViewClient.shouldOverrideUrlLoading()` filter | URL loading          | Depends on filter quality; bypassable with URL encoding, redirect chains, scheme variations                           |
| `CertificatePinner` / custom pinning              | MITM                 | **Effective** if implemented correctly; bypassable if the pinning check has logic errors or is applied to wrong hosts |

**For each sanitizer in the path, answer:**

1. What does it actually do (code-level)?
2. Is it appropriate for the vulnerability type?
3. Can it be bypassed? If so, how specifically?
4. Is it applied to ALL paths or just some?

### Step 3: Reachability Analysis

Can an attacker actually trigger this code path?

**Component reachability:**

- **Exported component** (no permission) — highly reachable from any app
- **Exported with normal/dangerous permission** — reachable from apps that hold the permission
- **Exported with signature permission** — reachable only from apps signed with same key (effectively internal)
- **Not exported** — only reachable internally or via deep links that resolve to it
- **Deep link registered** — reachable from any browser or app that can open the URL
- **Custom scheme** (`myapp://`) — reachable from any app; no browser sandbox protection
- **HTTPS scheme** (`https://example.com/path`) — reachable from browsers; has origin semantics

**Authentication reachability:**

- No auth check before vulnerable code — highly reachable
- Auth check in `onCreate()` or `onReceive()` before processing — reduces reachability to authenticated users
- Auth check only in UI, not in the component itself — reachability unchanged (can be called directly via `am`)

**Prerequisite reachability:**

- Requires specific app state (user logged in, item selected) — medium
- Requires specific Android version or device feature — varies
- Requires root or system access — low (but may be relevant for threat modeling)

### Step 4: Exploitability Assessment

Given the source, sanitizer, and reachability analysis — is the full path exploitable?

**Construct the complete attack path:**

```
Source (what input?) → Intermediate steps → Sanitizer (effective or bypassable?) → Sink (what dangerous operation?)
```

**Rate exploitability:**

- **TRIVIAL:** Attacker-controlled source, no effective sanitizer, exported component, no auth required
- **MODERATE:** Attacker-controlled source, bypassable sanitizer, requires user interaction or specific app state
- **COMPLEX:** Requires chained vulnerabilities, specific Android version, root access, or multiple user interactions
- **INFEASIBLE:** Source not attacker-controlled, or effective sanitizer in place on all paths, or component not reachable

### Step 5: Impact Analysis

If exploited, what does the attacker achieve?

Map to OWASP Mobile Top 10:

| Category                      | Impact Examples                                           |
| ----------------------------- | --------------------------------------------------------- |
| M1: Improper Platform Usage   | Misuse of platform APIs, intent misuse                    |
| M2: Insecure Data Storage     | Extract credentials from SharedPreferences, SQLite, files |
| M3: Insecure Communication    | Intercept or modify network traffic                       |
| M4: Insecure Authentication   | Bypass login, session hijacking                           |
| M5: Insufficient Cryptography | Decrypt protected data, forge tokens                      |
| M6: Insecure Authorization    | Access other users' data, escalate privileges             |
| M7: Client Code Quality       | Buffer overflows in native code, memory corruption        |
| M8: Code Tampering            | Modify app behavior, patch checks                         |
| M9: Reverse Engineering       | Extract secrets, understand business logic                |
| M10: Extraneous Functionality | Access developer backdoors, hidden endpoints              |

## Validation Output Schema

For each validated finding, produce this structured output:

```markdown
### Finding: [title]

- **Source:** [what input, how controlled, verdict]
- **Sink:** [what dangerous operation, file:line if known]
- **Path:** source → step1 → step2 → ... → sink (with file:line for each step)
- **Sanitizers:** [list each, rating: EFFECTIVE / BYPASSABLE (method) / INEFFECTIVE]
- **Reachability:** [exported? auth required? prerequisites?]
- **Verdict:** EXPLOITABLE / FALSE POSITIVE / NEEDS TESTING
- **Confidence:** 0.0–1.0
- **Exploitability:** TRIVIAL / MODERATE / COMPLEX / INFEASIBLE
- **Attack payload concept:** [brief description of what would work]
- **Impact:** [what attacker achieves, OWASP M-category]
- **CVSS estimate:** [vector string if enough data, or qualitative: critical/high/medium/low]
```

## Android-Specific Validation Patterns

### SQL Injection via Content Providers

**Source:** Content provider query parameter from external app calling `content://authority/table`
**Validation:**

1. Is the provider exported? (`android:exported="true"` or has intent-filters?)
2. Does it use `query()` with string concatenation for `selection`?
3. Does it use `rawQuery()` with string concatenation?
4. Is there a permission protection? (`android:readPermission` / `android:writePermission`)
5. Can the selection args be controlled independently?

**Dynamic proof:** Use `adb shell content query --uri content://authority/table --where "controlled_input"` and observe results.

### WebView JavaScript Bridge Abuse

**Source:** JavaScript executed in WebView, calling Java methods via `addJavascriptInterface`
**Validation:**

1. Is `setJavaScriptEnabled(true)` called?
2. Is `addJavascriptInterface()` called? What object is exposed?
3. Is the WebView loading external/content-provided URLs (not just hardcoded)?
4. What API level? Below API 17, all public methods are accessible via reflection.
5. Is `@JavascriptInterface` annotation used (required API 17+)?

**Dynamic proof:** Use chrome-devtools or Frida to call exposed methods from JS context.

### Intent Injection in Exported Components

**Source:** Intent extras from external app (any app can craft and send)
**Validation:**

1. Is the component exported?
2. Does it read extras and use them in sensitive operations (file access, component launching, SQL)?
3. Is there type validation on the extras (string vs parcelable vs int)?
4. Is there origin verification (checking the calling package)?

**Dynamic proof:** Use `am start -n component --es key value` or write a minimal PoC APK.

### Deep Link Abuse

**Source:** URI path/query parameters from any app or browser
**Validation:**

1. Is the deep link scheme registered in the manifest intent-filter?
2. Does the handler read `getData()`, `getQueryParameter()`, or `getPathSegments()`?
3. Does it use the data in file operations, URL loading, or component routing?
4. Is there validation on the URL scheme, host, or path before processing?

**Dynamic proof:** Use `am start -a android.intent.action.VIEW -d "scheme://host/path?param=value"`.

### Local Storage Exposure

**Source:** Filesystem access (requires root or adb backup for private files; world-readable files are accessible to any app)
**Validation:**

1. Are files written with `MODE_WORLD_READABLE` or `MODE_WORLD_WRITEABLE`? (deprecated but may still work)
2. Are SharedPreferences created with `MODE_WORLD_READABLE`?
3. Is `android:allowBackup="true"` in manifest? (enables `adb backup` extraction)
4. Are sensitive values stored in plaintext in SQLite, SharedPreferences, or files?
5. Can the data be extracted without root (via backup, exported provider, or world-readable file)?

**Dynamic proof:** `adb backup`, `adb shell run-as`, `adb shell cat /data/data/pkg/shared_prefs/`, Frida file monitor.

### Insecure Communication

**Source:** Network traffic sent over cleartext or with certificate pinning bypassed
**Validation:**

1. Does the app use HTTP (not HTTPS) for any requests?
2. Is `android:usesCleartextTraffic="true"` in manifest or network security config allows cleartext?
3. Is there certificate pinning? What implementation (OkHttp CertificatePinner, custom X509TrustManager, TrustKit)?
4. Can the pinning be bypassed with Frida (hook `checkServerTrusted`, `verify`)?
5. Are session tokens, API keys, or PII sent over vulnerable connections?

**Dynamic proof:** mitmproxy interception, Frida pinning bypass hooks from local library.

## Integration with Workflow

- **After Phase 3 (Static Triage):** Apply the 5-step validation to each suspected finding from jadx output and Semgrep scan. Classify as EXPLOITABLE, FALSE POSITIVE, or NEEDS TESTING.
- **Before Phase 9 (Prove Findings):** Only invest in PoC development for findings validated as EXPLOITABLE or NEEDS TESTING with confidence ≥ 0.6. FALSE POSITIVE findings are documented but not proven.
- **During Phase 10 (Confidence Review):** Update validation verdicts based on dynamic testing evidence. A finding that was NEEDS TESTING may be upgraded to EXPLOITABLE or downgraded to FALSE POSITIVE based on runtime behavior.
