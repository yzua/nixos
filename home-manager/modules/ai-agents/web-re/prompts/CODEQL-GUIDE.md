# CodeQL for Web Application Security Testing

## Why CodeQL

Semgrep (see SEMGREP-GUIDE.md) handles pattern-matching and basic taint tracking on client-side JS.
CodeQL provides **deep semantic analysis** with full taint tracking, call graph construction,
and dataflow path validation. Use CodeQL when:

- Semgrep flags a candidate but the dataflow path is ambiguous
- You need to prove reachability across multiple files/modules
- You need to validate that a sanitizer actually breaks the source-to-sink path
- You have server-side source code (not just client-side JS)
- You are building a definitive exploitability assessment for a high-value finding

CodeQL requires source code — it works on JavaScript, TypeScript, Python, Java, Go, Ruby, C/C++,
and C#. For web testing, the most common targets are JavaScript/TypeScript frontends and
Python/Java/Go backends.

## When to Use CodeQL vs Semgrep

| Scenario                                     | Tool    |
| -------------------------------------------- | ------- |
| Quick pattern scan on discovered JS          | Semgrep |
| Deep taint tracking on full source           | CodeQL  |
| No source available (only bundled JS)        | Semgrep |
| Need to prove a specific source-to-sink path | CodeQL  |
| Validate a sanitizer breaks a chain          | CodeQL  |
| Scan many files fast                         | Semgrep |
| Server-side code analysis                    | CodeQL  |

## Setup

```bash
# Install CodeQL CLI
mkdir -p ~/.local/share/codeql
cd ~/.local/share/codeql
wget https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip
unzip codeql-linux64.zip
export PATH="$HOME/.local/share/codeql/codeql:$PATH"

# Verify
codeql version

# Download standard query suites for web languages
codeql pack download codeql/javascript-queries
codeql pack download codeql/python-queries
codeql pack download codeql/java-queries
codeql pack download codeql/go-queries
```

## Creating a Database

### From Downloaded Source Code

When you discover server-side source (Git repo leak, public repository, or provided codebase):

```bash
# Auto-detect language
codeql database create ~/Documents/<target>/analysis/codeql-db \
  --language=javascript \
  --source-root=<source-dir> \
  --overwrite

# For Python backends
codeql database create ~/Documents/<target>/analysis/codeql-db \
  --language=python \
  --source-root=<source-dir> \
  --overwrite

# For mixed-language projects, create separate databases
codeql database create ~/Documents/<target>/analysis/codeql-db-js \
  --language=javascript \
  --source-root=<source-dir> \
  --overwrite

codeql database create ~/Documents/<target>/analysis/codeql-db-py \
  --language=python \
  --source-root=<source-dir> \
  --overwrite
```

### From Discovered JavaScript Files

For client-side analysis when you don't have the full source tree:

```bash
# Collect all JS files discovered during mapping
mkdir -p ~/Documents/<target>/analysis/js-source/
# Copy/symlink discovered JS files into this directory

codeql database create ~/Documents/<target>/analysis/codeql-db-js \
  --language=javascript \
  --source-root=~/Documents/<target>/analysis/js-source/ \
  --overwrite
```

## Running Queries

### Standard Security Query Suites

```bash
# JavaScript security queries
codeql database analyze ~/Documents/<target>/analysis/codeql-db \
  codeql/javascript-queries:Security \
  --format=sarif-latest \
  --output=~/Documents/<target>/analysis/codeql-results.sarif

# Python security queries
codeql database analyze ~/Documents/<target>/analysis/codeql-db \
  codeql/python-queries:Security \
  --format=sarif-latest \
  --output=~/Documents/<target>/analysis/codeql-results.sarif

# Specific CWE categories
codeql database analyze ~/Documents/<target>/analysis/codeql-db \
  codeql/javascript-queries:Security/CWE-079 \    # XSS
  --format=sarif-latest \
  --output=~/Documents/<target>/analysis/codeql-xss.sarif

codeql database analyze ~/Documents/<target>/analysis/codeql-db \
  codeql/javascript-queries:Security/CWE-089 \    # SQL Injection
  --format=sarif-latest \
  --output=~/Documents/<target>/analysis/codeql-sqli.sarif

codeql database analyze ~/Documents/<target>/analysis/codeql-db \
  codeql/javascript-queries:Security/CWE-022 \    # Path Traversal
  --format=sarif-latest \
  --output=~/Documents/<target>/analysis/codeql-path-traversal.sarif

codeql database analyze ~/Documents/<target>/analysis/codeql-db \
  codeql/javascript-queries:Security/CWE-918 \    # SSRF
  --format=sarif-latest \
  --output=~/Documents/<target>/analysis/codeql-ssrf.sarif
```

### Reviewing Results

```bash
# Extract findings from SARIF
cat ~/Documents/<target>/analysis/codeql-results.sarif | \
  jq '.runs[].results[] | {rule: .ruleId, message: .message.text, location: .locations[0].physicalLocation.artifactLocation.uri, line: .locations[0].physicalLocation.region.startLine}'

# Count findings by rule
cat ~/Documents/<target>/analysis/codeql-results.sarif | \
  jq '.runs[].results | group_by(.ruleId) | map({rule: .[0].ruleId, count: length}) | sort_by(-.count)'
```

## Web-Specific CodeQL Queries

### Custom Query: HTTP Parameter to DOM Sink (Reflected XSS)

```ql
/**
 * @name Web: HTTP parameter flows to DOM sink
 * @description Detects data flow from HTTP request parameters to dangerous DOM sinks
 * @kind path-problem
 * @problem.severity error
 * @security-severity 8.0
 * @id web/http-param-to-dom-xss
 * @tags security
 *       external/cwe/cwe-079
 */

import javascript
import semmle.code.javascript.dataflow.TaintTracking
import semmle.code.javascript.dataflow.RemoteFlowSources

module HttpToDomConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    source instanceof RemoteFlowSource::Range
  }

  predicate isSink(DataFlow::Node sink) {
    exists(DOM::ElementWrite ew |
      sink.asExpr() = ew.getValue()
    )
    or
    exists(DataFlow::CallNode call |
      call.getCalledTarget().hasName("innerHTML") and
      sink = call.getArgument(0)
    )
    or
    exists(DataFlow::CallNode call |
      call.getCalledTarget().hasName("document.write") and
      sink = call.getArgument(0)
    )
  }
}

module HttpToDomFlow = TaintTracking::Global<HttpToDomConfig>;
import HttpToDomFlow::PathGraph

from HttpToDomFlow::PathNode source, HttpToDomFlow::PathNode sink
where HttpToDomFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "User input from $@ flows to DOM sink, potential reflected XSS.",
  source.getNode(), "HTTP request"
```

### Custom Query: User Input to SQL Query (SQL Injection)

```ql
/**
 * @name Web: User input to SQL query
 * @kind path-problem
 * @problem.severity error
 * @id web/user-input-to-sqli
 */

import python
import semmle.code.python.dataflow.new.TaintTracking
import semmle.code.python.dataflow.new.RemoteFlowSources

module UserToSqlConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    source instanceof RemoteFlowSource::Range
  }

  predicate isSink(DataFlow::Node sink) {
    exists(Call call |
      call.getFunc().(Attribute).getName() = "execute" and
      call.getFunc().(Attribute).getObject().(Name).getId() = "cursor" and
      sink.asExpr() = call.getArg(0)
    )
  }
}

module UserToSqlFlow = TaintTracking::Global<UserToSqlConfig>;
import UserToSqlFlow::PathGraph

from UserToSqlFlow::PathNode source, UserToSqlFlow::PathNode sink
where UserToSqlFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "User input from $@ flows to SQL query, potential SQL injection.",
  source.getNode(), "HTTP request"
```

### Custom Query: Hardcoded Secrets in Configuration

```ql
/**
 * @name Web: Hardcoded secret in configuration
 * @kind problem
 * @problem.severity warning
 * @id web/hardcoded-secret
 */

import javascript

from StringLiteral lit, Property prop
where
  prop.getInit() = lit and
  (
    prop.getName().regexpMatch("(?i).*(api.key|secret|password|token|auth|credential|private.key).*")
  ) and
  lit.getValue().length() > 5
select lit, "Hardcoded secret for $S: $S.", prop.getName(), lit.getValue()
```

### Custom Query: Prototype Pollution Source to Merge

```ql
/**
 * @name Web: Prototype pollution via deep merge
 * @kind path-problem
 * @problem.severity warning
 * @id web/prototype-pollution
 */

import javascript
import semmle.code.javascript.dataflow.TaintTracking
import semmle.code.javascript.dataflow.RemoteFlowSources

module ProtoPollutionConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    source instanceof RemoteFlowSource::Range
  }

  predicate isSink(DataFlow::Node sink) {
    exists(DataFlow::PropWrite pw |
      pw.getPropertyName() = "__proto__" and
      sink = pw.getValue()
    )
    or
    exists(DataFlow::PropWrite pw |
      pw.getPropertyName() = "constructor" and
      sink = pw.getValue()
    )
  }
}

module ProtoPollutionFlow = TaintTracking::Global<ProtoPollutionConfig>;
import ProtoPollutionFlow::PathGraph

from ProtoPollutionFlow::PathNode source, ProtoPollutionFlow::PathNode sink
where ProtoPollutionFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "User input from $@ reaches prototype property write, potential prototype pollution.",
  source.getNode(), "HTTP request"
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

1. Identify the source (where attacker data enters: HTTP params, headers, cookies, WebSocket messages)
2. Identify the sink (where the dangerous operation happens: SQL query, DOM write, file access, HTTP redirect)
3. Write the configuration module with `isSource` and `isSink` predicates
4. Add `isAdditionalTaintStep` if the data flows through intermediate functions
5. Test against the database and review the paths

### Tips for Web Queries

- JavaScript frameworks use different patterns: React (JSX), Angular (templates), Vue (directives)
- For server-side: match on ORM/database driver methods for SQL sinks
- HTTP response headers are sinks for header injection
- `eval()`, `new Function()`, `setTimeout(string)`, `setInterval(string)` are JS execution sinks
- For path traversal: match on `fs.readFile`, `fs.writeFile`, `path.join` with user input
- Remote flow sources (`RemoteFlowSource`) capture HTTP params, headers, and body data

## Integrating CodeQL with Dataflow Validation

CodeQL produces taint paths with source and sink locations. Use the 5-step validation framework
(see DATAFLOW-VALIDATION.md) on each CodeQL finding:

1. **Source Control** — CodeQL already identifies the source. Verify it is attacker-controlled.
2. **Sanitizer Effectiveness** — CodeQL tracks some sanitizers. Check if the path passes through
   validation that actually neutralizes the attack.
3. **Reachability** — CodeQL shows the path, but verify the endpoint is publicly accessible.
4. **Exploitability** — Assess attack complexity from the CodeQL path.
5. **Impact** — Classify using OWASP Top 10.

CodeQL path results map directly to the dataflow validation schema:

```
CodeQL source node → source_control_verdict
CodeQL path edges  → intermediate_nodes
CodeQL sink node   → sink_description
CodeQL path        → dataflow_path
```

## Workflow Integration

In the phased workflow (see WORKFLOW.md):

1. **Phase 3 (Application Mapping)** — Discover JS files and source code
2. **Phase 3.5 (Semgrep Scan)** — Run Semgrep first for fast pattern matching
3. **Phase 3.6 (CodeQL Deep Analysis)** — For high-value candidates or when Semgrep cannot
   resolve dataflow, run CodeQL with targeted queries
4. **Phase 5.5 (Dataflow Validation)** — Apply validation framework to CodeQL results

Save CodeQL databases to `~/Documents/<target>/analysis/codeql-db/` and results to
`~/Documents/<target>/analysis/codeql-*.sarif`.

## Practical Tips

- CodeQL is significantly slower than Semgrep — only use it for deep analysis of high-value targets
- Always try Semgrep first; escalate to CodeQL when Semgrep results are ambiguous
- Custom queries can be saved in `~/Documents/<target>/analysis/codeql-queries/`
- For path-problem queries, the SARIF output includes the full source-to-sink path
- Use `--threads=0` to use all available CPU cores
- For JavaScript, CodeQL handles both plain JS and TypeScript
- If you discover a `.git` directory leak, clone the full repo for CodeQL analysis
