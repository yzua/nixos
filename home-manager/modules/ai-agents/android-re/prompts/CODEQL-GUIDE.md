# CodeQL for Android Reverse Engineering

## Why CodeQL

Semgrep (see SEMGREP-GUIDE.md) handles pattern-matching and basic taint tracking on jadx output.
CodeQL provides **deep semantic analysis** with full taint tracking, call graph construction,
and dataflow path validation. Use CodeQL when:

- Semgrep flags a candidate but the dataflow path is ambiguous
- You need to prove reachability across multiple methods/classes
- You need to validate that a sanitizer actually breaks the source-to-sink path
- You are building a definitive exploitability assessment for a high-value finding

CodeQL requires a **compilable build** — it does not work on decompiled jadx output directly.
For Android, this means either the original source or a rebuildable APK with `apktool` + Gradle.

## When to Use CodeQL vs Semgrep

| Scenario                                     | Tool    |
| -------------------------------------------- | ------- |
| Quick pattern scan on jadx output            | Semgrep |
| Deep taint tracking on compilable source     | CodeQL  |
| No build available (only decompiled)         | Semgrep |
| Need to prove a specific source-to-sink path | CodeQL  |
| Validate a sanitizer breaks a chain          | CodeQL  |
| Scan many APKs fast                          | Semgrep |

## Setup

```bash
# Install CodeQL CLI
# Download from https://github.com/github/codeql-cli-binaries/releases
# Or use the nix package if available
nix run nixpkgs#codeql -- --version

# Alternatively, download directly
mkdir -p ~/.local/share/codeql
cd ~/.local/share/codeql
wget https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip
unzip codeql-linux64.zip
export PATH="$HOME/.local/share/codeql/codeql:$PATH"

# Verify
codeql version

# Download standard query suites
codeql pack download codeql/java-queries
codeql pack download codeql/java-all
```

## Creating a Database

### From Source (APK Rebuilt with apktool)

```bash
# If you can rebuild the APK
apktool d target.apk -o rebuilt/
cd rebuilt

# CodeQL auto-detects Java/Android builds
codeql database create ~/Documents/<app>/analysis/codeql-db \
  --language=java \
  --source-root=. \
  --overwrite

# If auto-detection fails, specify the build command
codeql database create ~/Documents/<app>/analysis/codeql-db \
  --language=java \
  --command="./gradlew assembleDebug" \
  --source-root=. \
  --overwrite
```

### From Decompiled Source (Limited — No Build)

If no build is available, create a database from the jadx output for structural queries only.
Taint tracking will be limited because CodeQL cannot resolve all types without compilation:

```bash
# Structural analysis only — taint tracking limited
codeql database create ~/Documents/<app>/analysis/codeql-db-struct \
  --language=java \
  --source-root=~/.cache/android-re/out/<app>/jadx/sources/ \
  --overwrite
```

## Running Queries

### Standard Query Suites

```bash
# Run all Java security queries
codeql database analyze ~/Documents/<app>/analysis/codeql-db \
  codeql/java-queries:Security \
  --format=sarif-latest \
  --output=~/Documents/<app>/analysis/codeql-results.sarif

# Run specific query categories
codeql database analyze ~/Documents/<app>/analysis/codeql-db \
  codeql/java-queries:Security/CWE-089 \    # SQL Injection
  --format=sarif-latest \
  --output=~/Documents/<app>/analysis/codeql-sqli.sarif

codeql database analyze ~/Documents/<app>/analysis/codeql-db \
  codeql/java-queries:Security/CWE-079 \    # XSS (for WebViews)
  --format=sarif-latest \
  --output=~/Documents/<app>/analysis/codeql-xss.sarif

codeql database analyze ~/Documents/<app>/analysis/codeql-db \
  codeql/java-queries:Security/CWE-022 \    # Path Traversal
  --format=sarif-latest \
  --output=~/Documents/<app>/analysis/codeql-path-traversal.sarif

# Run all security queries and generate HTML report
codeql database analyze ~/Documents/<app>/analysis/codeql-db \
  codeql/java-queries:Security \
  --format=sarif-latest \
  --output=~/Documents/<app>/analysis/codeql-results.sarif

codeql github upload-results --sarif=~/Documents/<app>/analysis/codeql-results.sarif \
  --repository=local-analysis
```

### Reviewing Results

```bash
# Extract findings from SARIF
cat ~/Documents/<app>/analysis/codeql-results.sarif | \
  jq '.runs[].results[] | {rule: .ruleId, message: .message.text, location: .locations[0].physicalLocation.artifactLocation.uri, line: .locations[0].physicalLocation.region.startLine}'

# Count findings by severity
cat ~/Documents/<app>/analysis/codeql-results.sarif | \
  jq '.runs[].results | group_by(.level) | map({level: .[0].level, count: length})'
```

## Android-Specific CodeQL Queries

### Custom Query: Exported Component Receives Intent Data Flows to SQL

```ql
/**
 * @name Android: Intent data flows to SQL query
 * @description Detects data flow from Intent extras in exported components to SQL queries
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.0
 * @id android/intent-to-sqli
 * @tags security
 *       external/cwe/cwe-089
 */

import java
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.dataflow.FlowSources

module IntentToSqlConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    exists(MethodCall mc |
      mc.getMethod().hasName("getStringExtra") and
      source.asExpr() = mc
    )
    or
    exists(MethodCall mc |
      mc.getMethod().hasName("getQueryParameter") and
      source.asExpr() = mc
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(MethodCall mc |
      mc.getMethod().hasName("rawQuery") and
      sink.asExpr() = mc.getArgument(0)
    )
    or
    exists(MethodCall mc |
      mc.getMethod().hasName("execSQL") and
      sink.asExpr() = mc.getArgument(0)
    )
  }
}

module IntentToSqlFlow = TaintTracking::Global<IntentToSqlConfig>;
import IntentToSqlFlow::PathGraph

from IntentToSqlFlow::PathNode source, IntentToSqlFlow::PathNode sink
where IntentToSqlFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Intent data from $@ flows to SQL query, potential SQL injection.",
  source.getNode(), "Intent extra"
```

### Custom Query: Deep Link URL Flows to WebView

```ql
/**
 * @name Android: Deep link URL loaded into WebView without validation
 * @kind path-problem
 * @problem.severity warning
 * @id android/deeplink-to-webview
 */

import java
import semmle.code.java.dataflow.TaintTracking

module DeepLinkToWebviewConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    exists(MethodCall mc |
      mc.getMethod().hasName("getData") and
      mc.getEnclosingCallable().hasName("onCreate") and
      source.asExpr() = mc
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(MethodCall mc |
      mc.getMethod().hasName("loadUrl") and
      mc.getMethod().getDeclaringType().hasName("WebView") and
      sink.asExpr() = mc.getArgument(0)
    )
  }
}

module DeepLinkToWebviewFlow = TaintTracking::Global<DeepLinkToWebviewConfig>;
import DeepLinkToWebviewFlow::PathGraph

from DeepLinkToWebviewFlow::PathNode source, DeepLinkToWebviewFlow::PathNode sink
where DeepLinkToWebviewFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Deep link URL from $@ loaded into WebView without validation.",
  source.getNode(), "intent data"
```

### Custom Query: Hardcoded Cryptographic Keys

```ql
/**
 * @name Android: Hardcoded cryptographic key
 * @kind problem
 * @problem.severity warning
 * @id android/hardcoded-crypto-key
 */

import java

from StringLiteral lit, MethodCall mc
where
  mc.getMethod().hasName("SecretKeySpec") and
  lit = mc.getArgument(0) and
  lit.getValue().length() > 0
select lit, "Hardcoded key material passed to SecretKeySpec: $S.", lit.getValue()
```

### Custom Query: Insecure SharedPreferences Storage

```ql
/**
 * @name Android: Sensitive data stored in SharedPreferences without encryption
 * @kind problem
 * @problem.severity warning
 * @id android/insecure-sharedprefs
 */

import java

from MethodCall store, string sensitiveKey
where
  (
    store.getMethod().hasName("putString") or
    store.getMethod().hasName("putInt") or
    store.getMethod().hasName("putFloat") or
    store.getMethod().hasName("putLong") or
    store.getMethod().hasName("putBoolean")
  ) and
  store.getMethod().getDeclaringType().hasName("SharedPreferences$Editor") and
  (
    store.getArgument(0).(StringLiteral).getValue().regexpMatch("(?i).*(password|token|secret|key|auth|session|cookie).*")
  )
select store, "Sensitive data stored in SharedPreferences without encryption: $S.",
  store.getArgument(0).(StringLiteral).getValue()
```

## Writing Custom Queries

### Query Structure

Every CodeQL query has:

1. **Metadata** — name, description, severity, ID, tags
2. **Imports** — language libraries, dataflow modules
3. **Configuration** — source and sink predicates (for taint tracking)
4. **Module** — `TaintTracking::Global<Config>` for path queries
5. **Select** — the `from...where...select` that produces results

### Steps to Write a New Query

1. Identify the source (where attacker data enters: Intent extras, URI parameters, Bundle data)
2. Identify the sink (where the dangerous operation happens: SQL query, WebView load, file access, network call)
3. Write the configuration module with `isSource` and `isSink` predicates
4. Add `isAdditionalTaintStep` if the data flows through intermediate methods
5. Test against the database and review the paths

### Tips for Android Queries

- Android APIs use overloaded method names — match on both method name and declaring type
- Intent data flows through many intermediate calls: `getIntent()`, `getData()`, `getStringExtra()`, etc.
- Content provider queries use `query()`, `insert()`, `update()`, `delete()` — these are sinks for injection
- WebView bridges registered with `addJavascriptInterface` create custom sinks
- Use `exists(MethodCall mc | ...)` to find specific API patterns

## Integrating CodeQL with Dataflow Validation

CodeQL produces taint paths with source and sink locations. Use the 5-step validation framework
(see DATAFLOW-VALIDATION.md) on each CodeQL finding:

1. **Source Control** — CodeQL already identifies the source. Verify it is attacker-controlled.
2. **Sanitizer Effectiveness** — CodeQL tracks some sanitizers. Check if the path passes through
   validation that actually neutralizes the attack.
3. **Reachability** — CodeQL shows the path, but verify the component is exported and reachable.
4. **Exploitability** — Assess attack complexity from the CodeQL path.
5. **Impact** — Classify using OWASP Mobile Top 10.

CodeQL path results map directly to the dataflow validation schema:

```
CodeQL source node → source_control_verdict
CodeQL path edges  → intermediate_nodes
CodeQL sink node   → sink_description
CodeQL path        → dataflow_path
```

## Workflow Integration

In the phased workflow (see WORKFLOW.md):

1. **Phase 3 (Static Triage)** — Run Semgrep first for fast pattern matching
2. **Phase 3.7 (Semgrep Scan)** — Classify Semgrep candidates
3. **Phase 3.9 (CodeQL Deep Analysis)** — For high-value candidates or when Semgrep cannot
   resolve dataflow, run CodeQL with targeted queries
4. **Phase 3.10 (Dataflow Validation)** — Apply validation framework to CodeQL results

Save CodeQL databases to `~/Documents/<app>/analysis/codeql-db/` and results to
`~/Documents/<app>/analysis/codeql-*.sarif`.

## Practical Tips

- CodeQL is significantly slower than Semgrep — only use it for deep analysis of high-value targets
- Always try Semgrep first; escalate to CodeQL when Semgrep results are ambiguous
- Custom queries can be saved in `~/Documents/<app>/analysis/codeql-queries/`
- For path-problem queries, the SARIF output includes the full source-to-sink path
- Use `--threads=0` to use all available CPU cores
- Large APKs may take 10-30 minutes for database creation; cache the database between sessions
