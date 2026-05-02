# Semgrep for Web Application Security Testing

## Why Semgrep

Dynamic testing tools (nuclei, sqlmap, dalfox) find vulnerabilities by sending payloads. Semgrep finds vulnerabilities by analyzing source code patterns. Using both catches more:

- Scans discovered JavaScript files, API response schemas, and server-side code (if accessible)
- Pattern-matching rules catch known vulnerability patterns in seconds
- Taint-tracking rules trace data from source (user input) to sink (dangerous operation)
- JSON output integrates with the validation workflow
- Custom rules are simple YAML

## Setup

```bash
# Install via pip (recommended for NixOS)
pip install --user semgrep

# Or run without installing
uvx semgrep --help

# Verify
semgrep --version
```

## Running Semgrep Against Web Targets

### Scanning Downloaded JavaScript

After Phase 3 (Application Mapping) discovers JS files:

```bash
# Download JS files discovered during mapping
mkdir -p ~/Documents/<target>/analysis/js-source
# (Use chrome-devtools or curl to download each JS URL)

# Scan all downloaded JS
semgrep --config auto ~/Documents/<target>/analysis/js-source/ \
  --json -o ~/Documents/<target>/analysis/semgrep-js-results.json

# Scan with JavaScript-specific rules
semgrep --config p/javascript ~/Documents/<target>/analysis/js-source/
semgrep --config p/owasp-top-ten ~/Documents/<target>/analysis/js-source/
```

### Scanning Server-Side Code (If Accessible)

If source code is accessible (open-source target, git repo discovered, backup files exposed):

```bash
# Clone or download source
git clone <discovered-repo> ~/Documents/<target>/analysis/server-source/

# Scan
semgrep --config auto ~/Documents/<target>/analysis/server-source/ \
  --json -o ~/Documents/<target>/analysis/semgrep-server-results.json
```

### Scanning API Response Schemas

If OpenAPI/Swagger specs are discovered:

```bash
# Check for security issues in API definitions
semgrep --config p/owasp-top-ten ~/Documents/<target>/analysis/api-specs/
```

## Web-Relevant Rule Categories

### SQL Injection

```yaml
# Detects string concatenation in SQL queries
rules:
  - id: web.sqli.concatenation
    languages: [python, javascript, php, ruby]
    severity: ERROR
    pattern-either:
      - pattern: |
          $DB.execute("SELECT ..." + $INPUT)
      - pattern: |
          $DB.query(`SELECT ...${$INPUT}`)
      - pattern: |
          cursor.execute("... %s" % $INPUT)
    message: "String concatenation in SQL query — use parameterized queries"
```

### Command Injection

```yaml
# Detects user input passed to shell commands
rules:
  - id: web.cmdi.subprocess-shell
    languages: [python]
    severity: ERROR
    mode: taint
    pattern-sources:
      - pattern: request.$METHOD[$_]
      - pattern: flask.request.$ATTR[$_]
    pattern-sinks:
      - pattern: subprocess.run($CMD, ..., shell=True, ...)
      - pattern: os.system($CMD)
      - pattern: os.popen($CMD)
    pattern-sanitizers:
      - pattern: shlex.quote(...)
    message: "User input reaches shell command — command injection"
```

### XSS (Client-Side)

```yaml
# DOM-based XSS sinks
rules:
  - id: web.xss.innerhtml
    languages: [javascript, typescript]
    severity: ERROR
    patterns:
      - pattern: $EL.innerHTML = $INPUT
      - metavariable-pattern:
          metavariable: $INPUT
          pattern-either:
            - pattern: document.location.hash
            - pattern: new URLSearchParams(...).get(...)
            - pattern: location.search
            - pattern: $INPUT # catch all assignments
    message: "Unsanitized input assigned to innerHTML — DOM XSS"

  - id: web.xss.document-write
    languages: [javascript, typescript]
    severity: ERROR
    patterns:
      - pattern: document.write($INPUT)
      - metavariable-pattern:
          metavariable: $INPUT
          pattern-either:
            - pattern: location.search
            - pattern: document.location.hash
            - pattern: new URLSearchParams(...).get(...)
    message: "User-controlled data passed to document.write — DOM XSS"
```

### Hardcoded Secrets

```yaml
rules:
  - id: web.secrets.hardcoded
    languages: [javascript, typescript, python]
    severity: ERROR
    pattern-either:
      - pattern: |
          const $VAR = "sk_live_..."
      - pattern: |
          const $VAR = "AKIA..."
      - pattern: |
          const $VAR = "Bearer ..."
      - pattern: |
          $API_KEY = "ghp_..."
      - pattern: |
          password = "..."
    message: "Potential hardcoded secret"
```

### Path Traversal

```yaml
rules:
  - id: web.path-traversal
    languages: [python, javascript, typescript]
    severity: ERROR
    patterns:
      - pattern: open($INPUT, ...)
      - metavariable-pattern:
          metavariable: $INPUT
          pattern-either:
            - pattern: request.$METHOD[$_]
            - pattern: req.params[$_]
            - pattern: req.query[$_]
    message: "User input used in file path — potential path traversal"
```

### SSRF

```yaml
rules:
  - id: web.ssrf.fetch-from-input
    languages: [python, javascript, typescript]
    severity: ERROR
    mode: taint
    pattern-sources:
      - pattern: request.$METHOD[$_]
      - pattern: req.query[$_]
      - pattern: req.params[$_]
      - pattern: req.body[$_]
    pattern-sinks:
      - pattern: requests.get($URL, ...)
      - pattern: fetch($URL, ...)
      - pattern: urllib.request.urlopen($URL, ...)
      - pattern: axios.get($URL, ...)
    message: "User-controlled URL — potential SSRF"
```

### TLS Bypass

```yaml
rules:
  - id: web.tls.verify-false
    languages: [python]
    severity: WARNING
    pattern-either:
      - pattern: requests.get($URL, verify=False, ...)
      - pattern: requests.post($URL, verify=False, ...)
    message: "TLS certificate verification disabled"
```

## Web-Specific Custom Rules

### React dangerouslySetInnerHTML

```yaml
rules:
  - id: web.react.dangerously-set-inner-html
    languages: [javascript, typescript, jsx, tsx]
    severity: WARNING
    pattern: |
      dangerouslySetInnerHTML={__html: $INPUT}
    message: "dangerouslySetInnerHTML with dynamic value — ensure input is sanitized"
```

### Insecure jQuery Patterns

```yaml
rules:
  - id: web.jquery.html-from-input
    languages: [javascript]
    severity: ERROR
    pattern-either:
      - pattern: $($SEL).html($INPUT)
      - pattern: $($SEL).append($INPUT)
      - pattern: $($SEL).prepend($INPUT)
    message: "jQuery HTML injection method with potentially unsanitized input"
```

### Prototype Pollution

```yaml
rules:
  - id: web.js.prototype-pollution
    languages: [javascript, typescript]
    severity: WARNING
    pattern-either:
      - pattern: Object.assign({}, $INPUT)
      - pattern: _.merge($TARGET, $INPUT)
      - pattern: $.extend(true, $TARGET, $INPUT)
    message: "Deep merge with user input — potential prototype pollution"
```

### eval and Function Constructor

```yaml
rules:
  - id: web.js.eval-usage
    languages: [javascript, typescript]
    severity: ERROR
    pattern-either:
      - pattern: eval($INPUT)
      - pattern: new Function($INPUT)
      - pattern: setTimeout($INPUT, ...) # string argument form
    message: "eval/Function constructor with potentially dynamic input — code injection"
```

## Integrating Semgrep with Dataflow Validation

Semgrep produces candidate findings. Apply the 5-step validation framework (see DATAFLOW-VALIDATION.md) to each:

1. Semgrep finds `innerHTML` assignment from `location.hash` → **candidate finding**
2. Validate: Is the source attacker-controlled? (URL fragment — yes, fully controlled)
3. Validate: Is there a sanitizer? (DOMPurify? Manual encoding?)
4. Validate: Is the code path reachable? (Is this JS actually loaded on the page?)
5. Classify: EXPLOITABLE / FALSE POSITIVE / NEEDS TESTING

**Workflow:**

```bash
# 1. After Phase 3 mapping, download all JS files
mkdir -p ~/Documents/<target>/analysis/js-source
# Use chrome-devtools list_network_requests to find JS URLs
# Use curl to download each

# 2. Run Semgrep
semgrep --config auto --json ~/Documents/<target>/analysis/js-source/ \
  -o ~/Documents/<target>/analysis/semgrep-results.json

# 3. Review results
cat ~/Documents/<target>/analysis/semgrep-results.json | jq '.results[] | {rule: .check_id, file: .path, line: .start.line, message: .extra.message}'

# 4. For each candidate, validate with chrome-devtools (navigate to page, test context)
# 5. Apply validation framework
# 6. Write validated findings to ~/Documents/<target>/analysis/validated-findings.md
```

## Practical Tips

- Run Semgrep on downloaded JS after Phase 3 mapping, before Phase 6 vulnerability testing
- Use `--json` output for automated processing; use `--text` for quick review
- Community rules (`--config auto`) cover common patterns; custom rules catch framework-specific issues
- For minified JS, try `--no-git-ignore` and consider using a JS beautifier first
- Combine Semgrep findings with chrome-devtools verification — Semgrep catches patterns, DevTools confirms exploitability
- Semgrep taint rules (`mode: taint`) are slower but more accurate for tracking data flow through source
- If you discover `.env`, `config.json`, or `package.json` files during recon, scan those too
