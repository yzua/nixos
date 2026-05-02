# Semgrep for Android Reverse Engineering

## Why Semgrep

Static triage currently uses manual `grep` patterns across jadx output. Semgrep fills the gap between manual grep and full CodeQL analysis:

- Runs on plain Java/Kotlin source (exactly what `jadx` produces) — no build required
- Supports both pattern-matching rules and taint-tracking rules (source → sink dataflow)
- Runs in seconds on typical APK source trees
- Output is structured JSON for automated processing
- Custom rules are simple YAML — easy to write Android-specific checks

## Setup

```bash
# Install via pip (recommended for NixOS)
pip install --user semgrep

# Or run without installing
uvx semgrep --help

# Verify
semgrep --version
```

## Running Semgrep Against JADX Output

After `re-static.sh prepare` or manual `jadx` decompilation, the source tree is at:

```
~/.cache/android-re/out/<app>/jadx/sources/
```

```bash
# Auto scan with community rules
semgrep --config auto ~/.cache/android-re/out/<app>/jadx/sources/ \
  --json -o ~/Documents/<app>/analysis/semgrep-results.json

# Scan with specific rule categories
semgrep --config p/owasp-top-ten ~/.cache/android-re/out/<app>/jadx/sources/
semgrep --config p/java ~/.cache/android-re/out/<app>/jadx/sources/

# Scan with custom rules (see below)
semgrep --config ~/Documents/<app>/analysis/semgrep-rules/ ~/.cache/android-re/out/<app>/jadx/sources/

# Text output for quick review
semgrep --config auto ~/.cache/android-re/out/<app>/jadx/sources/ --text
```

## Android-Relevant Rule Categories

### SQL Injection

Looks for string concatenation or interpolation in database query methods.

```yaml
# Example: detect string concatenation in rawQuery
rules:
  - id: android.sqli.raw-query-concat
    languages: [java]
    severity: ERROR
    pattern-either:
      - pattern: |
          $DB.rawQuery($QUERY + $REST, ...)
      - pattern: |
          $DB.rawQuery(String.format(...), ...)
    message: "String concatenation in rawQuery — potential SQL injection"
```

Targets: `SQLiteDatabase.rawQuery()`, `SQLiteDatabase.execSQL()`, `SQLiteQueryBuilder.query()`.

### Hardcoded Secrets

Detects API keys, tokens, and credentials embedded in source.

```yaml
rules:
  - id: android.secrets.hardcoded-key
    languages: [java]
    severity: ERROR
    pattern-either:
      - pattern: |
          String $KEY = "AKIA...";          # AWS access key pattern
      - pattern: |
          String $KEY = "sk_live_...";      # Stripe key pattern
      - pattern: |
          String $VAR = "Bearer ...";       # Hardcoded bearer token
    message: "Potential hardcoded secret"
```

### TLS and Certificate Pinning Bypass

Detects custom TrustManagers that accept all certificates.

```yaml
rules:
  - id: android.tls.trust-all
    languages: [java]
    severity: WARNING
    pattern-either:
      - pattern: |
          class $CLASS implements X509TrustManager {
            ...
            void checkServerTrusted(...) {}
            ...
          }
      - pattern: |
          TrustManager[] $TMS = { new X509TrustManager() { ... } };
    message: "Custom TrustManager accepts all certificates"
```

### Weak Cryptography

```yaml
rules:
  - id: android.crypto.weak-hash
    languages: [java]
    severity: WARNING
    pattern-either:
      - pattern: MessageDigest.getInstance("MD5")
      - pattern: MessageDigest.getInstance("SHA-1")
      - pattern: MessageDigest.getInstance("SHA1")
    message: "Weak hash algorithm — use SHA-256 or stronger"

  - id: android.crypto.ecb-mode
    languages: [java]
    severity: WARNING
    pattern-either:
      - pattern: Cipher.getInstance("AES/ECB/...")
    message: "ECB mode is deterministic — use CBC or GCM"
```

### Path Traversal

```yaml
rules:
  - id: android.path-traversal.file-from-input
    languages: [java]
    severity: WARNING
    patterns:
      - pattern: new File($INPUT, ...)
      - metavariable-pattern:
          metavariable: $INPUT
          pattern-either:
            - pattern: $INTENT.getStringExtra(...)
            - pattern: $URI.getPath()
            - pattern: $URI.getQueryParameter(...)
    message: "File path constructed from external input — potential path traversal"
```

### Logging Sensitive Data

```yaml
rules:
  - id: android.logging.secrets
    languages: [java]
    severity: WARNING
    patterns:
      - pattern: Log.$LEVEL($TAG, $MSG)
      - metavariable-pattern:
          metavariable: $MSG
          pattern-either:
            - pattern: password
            - pattern: token
            - pattern: secret
            - pattern: apiKey
            - pattern: credentials
    message: "Sensitive data may be logged"
```

### SSRF

```yaml
rules:
  - id: android.ssrf.url-from-input
    languages: [java]
    severity: ERROR
    patterns:
      - pattern: new URL($INPUT)
      - metavariable-pattern:
          metavariable: $INPUT
          pattern-either:
            - pattern: $INTENT.getStringExtra(...)
            - pattern: $URI.toString()
            - pattern: $BUNDLE.getString(...)
    message: "URL constructed from external input — potential SSRF"
```

## Android-Specific Custom Rules

These patterns are unique to Android and not covered by standard Semgrep rules:

### Exported Component Without Permission

```yaml
rules:
  - id: android.manifest.exported-no-permission
    languages: [xml]
    severity: WARNING
    patterns:
      - pattern-inside: |
          <activity android:exported="true" ...> ... </activity>
      - pattern-not-inside: |
          <activity android:exported="true" android:permission="..." ...> ... </activity>
    message: "Exported activity without permission protection"
```

### WebView JavaScript Enabled Without Same-Origin

```yaml
rules:
  - id: android.webview.js-enabled-no-sop
    languages: [java]
    severity: WARNING
    patterns:
      - pattern: $WEBVIEW.getSettings().setJavaScriptEnabled(true)
      - pattern-not: $WEBVIEW.getSettings().setAllowUniversalAccessFromFileURLs(false)
    message: "JavaScript enabled in WebView — verify same-origin policy is enforced"
```

### Backup Enabled With Sensitive Data

```yaml
rules:
  - id: android.manifest.backup-enabled
    languages: [xml]
    severity: INFO
    pattern: |
      <application ... android:allowBackup="true" ...>
    message: "Backup enabled — data extractable via adb backup"
```

### Unvalidated Deep Link URLs

```yaml
rules:
  - id: android.deeplink.unvalidated-url
    languages: [java]
    severity: WARNING
    patterns:
      - pattern: $WEBVIEW.loadUrl($URI.toString())
      - pattern-not: |
          if ($URI.getScheme().equals("https")) { ... }
    message: "Deep link URL loaded into WebView without scheme validation"
```

## Integrating Semgrep with Dataflow Validation

Semgrep produces candidate findings. Apply the 5-step validation framework (see DATAFLOW-VALIDATION.md) to each:

1. Semgrep finds a string concatenation in `rawQuery()` → **candidate finding**
2. Validate: Is the source attacker-controlled? (Intent extra from exported component?)
3. Validate: Is there a sanitizer? (parameterized query, input validation?)
4. Validate: Is the component reachable? (exported? permission-protected?)
5. Classify: EXPLOITABLE / FALSE POSITIVE / NEEDS TESTING

**Workflow:**

```bash
# 1. Run Semgrep
semgrep --config auto --json ~/.cache/android-re/out/<app>/jadx/sources/ \
  -o ~/Documents/<app>/analysis/semgrep-results.json

# 2. Review results and classify each finding
cat ~/Documents/<app>/analysis/semgrep-results.json | jq '.results[] | {rule: .check_id, file: .path, line: .start.line, message: .extra.message}'

# 3. For each candidate, trace the dataflow in jadx source manually
# 4. Apply validation framework
# 5. Write validated findings to ~/Documents/<app>/analysis/validated-findings.md
```

## Practical Tips

- Run Semgrep after `jadx` decompilation completes, before manual grep-based triage
- Use `--json` output for automated processing; use `--text` for quick review
- Community rules (`--config auto`) cover common patterns; custom rules catch Android-specific issues
- Semgrep taint rules (`mode: taint`) are more accurate than grep for tracking data flow, but slower
- For large APKs, scope Semgrep to specific packages: `--include="com/target/app/**/*.java"`
- Combine Semgrep findings with manual jadx analysis — Semgrep catches patterns, jadx context confirms exploitability
