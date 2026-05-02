# Findings Prioritization

## Adversarial Priority Order

Not all findings are equal. Prioritize by attacker impact — what can be exploited fastest with highest damage.

### 1. Secrets and Credentials (Instant Compromise)

**Why first:** No exploitation skill needed. Finding an exposed API key or admin password is a confirmed compromise.

**What to look for:**

- API keys exposed in client-side JavaScript (AWS, Stripe, Firebase, Google Maps, etc.)
- Hardcoded credentials in source code or config files
- Admin credentials in exposed `.env` files or config endpoints
- Cloud service tokens (AWS IAM keys, GCP service account keys)
- Private keys (SSH, TLS, signing keys) in accessible locations
- Database connection strings with embedded passwords

**Action:** Report immediately. These are always EXPLOITABLE.

### 2. Input Validation Issues (High Exploitability)

**Why second:** Most common and directly exploitable. SQL injection, XSS, and command injection are reliable attack vectors.

**What to look for:**

- SQL injection (union-based, blind, time-based, error-based)
- XSS (reflected, stored, DOM-based)
- Command injection (OS command execution via user input)
- SSRF (server fetches attacker-controlled URLs)
- Path traversal (file access via `../` or encoding bypasses)
- Insecure deserialization (pickle, YAML, JSON deserialization of user input)

**Action:** Validate with dataflow framework. If source is attacker-controlled and endpoint is public, classify as EXPLOITABLE.

### 3. Authentication and Authorization (Access Control Failures)

**Why third:** Enables unauthorized access but may require more setup (valid account, session manipulation).

**What to look for:**

- Broken access control (admin endpoints accessible to regular users)
- IDOR (sequential or predictable resource identifiers)
- Privilege escalation (regular user can modify roles or permissions)
- JWT issues (`alg: none`, weak signing key, RS256→HS256 confusion)
- Session fixation or session not invalidated after logout
- OAuth misconfiguration (open redirect, missing state parameter)
- Brute force possible (no rate limiting on login, predictable MFA bypass)

**Action:** Test with two different accounts. Verify cross-account access. Check JWT handling.

### 4. Cryptography Issues (Data Protection Failures)

**Why fourth:** Weakens data protection but usually requires chaining with another finding for full exploitation.

**What to look for:**

- Weak TLS configuration (outdated cipher suites, TLS 1.0/1.1)
- Weak password hashing (MD5, SHA-1 without salt)
- Hardcoded encryption keys in source
- Insecure random number generation
- Missing HSTS header
- Sensitive data transmitted over HTTP

**Action:** Document the weak crypto. Assess if it can be chained with a data access finding.

### 5. Configuration Issues (Security Baseline)

**Why last:** These increase attack surface but are rarely directly exploitable alone.

**What to look for:**

- Debug mode enabled in production (verbose errors, stack traces)
- Missing security headers (CSP, X-Frame-Options, X-Content-Type-Options)
- CORS misconfiguration (`Access-Control-Allow-Origin: *` with credentials)
- Verbose error messages exposing internal paths or software versions
- Directory listing enabled
- Default credentials on admin panels
- Missing rate limiting on sensitive endpoints

**Action:** Document as configuration hardening recommendations. These inform the overall security posture.

## Severity Adjudication Process

For each validated finding, rate along four axes:

### Attack Prerequisites

| Level                  | Description                        | Examples                          |
| ---------------------- | ---------------------------------- | --------------------------------- |
| **Unauthenticated**    | No account or auth needed          | Public API endpoint, login page   |
| **Authenticated user** | Requires a registered account      | Any logged-in user can exploit    |
| **Specific role**      | Requires a specific account type   | Premium user, moderator, employee |
| **Admin**              | Requires admin access              | Admin panel, admin API            |
| **Physical/network**   | Requires specific network position | Internal network, VPN access      |

### Reachability

| Level             | Description            | Examples                                          |
| ----------------- | ---------------------- | ------------------------------------------------- |
| **Public**        | Internet-accessible    | Any endpoint on the public URL                    |
| **Authenticated** | Requires session/token | API endpoints behind auth middleware              |
| **Admin-only**    | Requires admin session | Admin routes, internal dashboards                 |
| **Internal**      | Not exposed externally | Internal microservices, admin-only infrastructure |

### Data Sensitivity

| Level                       | Description                  | Examples                                       |
| --------------------------- | ---------------------------- | ---------------------------------------------- |
| **PII**                     | Personally identifiable info | Name, email, phone, SSN, address               |
| **Credentials**             | Auth credentials             | Passwords, tokens, session IDs, API keys       |
| **Financial**               | Payment or financial data    | Credit cards, bank accounts, transactions      |
| **Internal infrastructure** | Server/network details       | Internal IPs, database hosts, service versions |
| **None**                    | Non-sensitive data           | UI preferences, feature flags                  |

### Blast Radius

| Level                | Description                                       |
| -------------------- | ------------------------------------------------- |
| **Single user**      | Only affects one user's data                      |
| **All users**        | Affects every user of the application             |
| **Full database**    | Access to all stored data                         |
| **Internal network** | Access to internal services or infrastructure     |
| **Infrastructure**   | Server-level compromise (RCE, file system access) |

## Severity Rating

Combine the four axes:

| Combination                                                                             | Severity          |
| --------------------------------------------------------------------------------------- | ----------------- |
| Unauthenticated + Public + PII/Credentials/Financial + All users/Full DB/Infrastructure | **Critical**      |
| Unauthenticated + Public + Any sensitivity + Any blast radius                           | **High**          |
| Authenticated user + Public/Authenticated + PII/Credentials/Financial + All users       | **High**          |
| Authenticated user + Public/Authenticated + Any sensitivity + Single user               | **Medium**        |
| Specific role or Admin-only + Any sensitivity + Any blast radius                        | **Medium**        |
| Internal only + Any sensitivity                                                         | **Low**           |
| Configuration hardening with no direct exploit path                                     | **Informational** |

## Chaining Priority

When two findings can be combined, the resulting chain inherits the higher severity.

**Common high-impact chains:**

| Chain                                      | Individual Severity | Combined Severity |
| ------------------------------------------ | ------------------- | ----------------- |
| Open redirect + OAuth token theft          | Medium + Medium     | **Critical**      |
| Stored XSS + Admin session                 | High + Medium       | **Critical**      |
| IDOR + PII access                          | Medium + Medium     | **High**          |
| SSRF + Internal API keys                   | High + Critical     | **Critical**      |
| Information disclosure + Targeted phishing | Low + Medium        | **Medium**        |
| CORS misconfig + Credential theft          | Medium + High       | **High**          |
| Verbose errors + SQL injection discovery   | Low + Critical      | **Critical**      |

**Rule:** Document chains separately from individual findings. A chain PoC demonstrates the combined impact and justifies the elevated severity.

## Upgrade and Downgrade Rules

**Upgrade when:**

- Finding can be chained with another finding to increase impact
- The finding affects high-value data (financial, health, authentication)
- The finding is easier to exploit than initially assessed (e.g., WAF bypass confirmed)

**Downgrade when:**

- A confirmed effective mitigation exists on all paths
- The finding requires admin access and admin accounts are tightly controlled
- Rate limiting makes exploitation impractical
- The finding is in a non-production environment with no production impact

**Mark as FALSE POSITIVE when:**

- Source is not attacker-controlled after dataflow validation
- Effective sanitizer/encoding exists on all paths with no known bypass
- The endpoint is not reachable from the attacker's position
- The "vulnerability" is intentional behavior (e.g., a public health check endpoint)

## MITRE ATT&CK Enterprise Mapping

Map every confirmed finding to the relevant ATT&CK technique:

| Priority Category        | ATT&CK Technique                            | Description                                     |
| ------------------------ | ------------------------------------------- | ----------------------------------------------- |
| Exposed API keys/creds   | **T1552** Unsecured Credentials             | Keys in JS, config files, source code           |
| SQL injection            | **T1190** Exploit Public-Facing Application | Injection via web parameters or API inputs      |
| XSS                      | **T1189** Drive-by Compromise               | Reflected/stored/DOM XSS for session hijack     |
| Command injection        | **T1059** Command and Scripting Interpreter | OS command execution via user input             |
| SSRF                     | **T1190** Exploit Public-Facing Application | Internal service access, cloud metadata         |
| Path traversal           | **T1083** File and Directory Discovery      | Unauthorized file access via `../`              |
| Broken access control    | **T1078** Valid Accounts                    | IDOR, privilege escalation, missing auth checks |
| IDOR                     | **T1530** Data from Local System            | Accessing other users' data via predictable IDs |
| JWT/session manipulation | **T1537** Transfer Data to Cloud Account    | Token theft, session fixation, replay           |
| CSRF                     | **T1531** Account Access Removal            | Forged state-changing requests                  |
| CORS misconfiguration    | **T1190** Exploit Public-Facing Application | Cross-origin data theft                         |
| Weak TLS                 | **T1573** Encrypted Channel                 | Outdated protocols, weak cipher suites          |
| Broken crypto            | **T1600** Weaken Encryption                 | Weak hashing, hardcoded keys                    |
| Open redirect            | **T1200** Hardware Additions                | Redirect-based token theft                      |
| Insecure deserialization | **T1059** Command and Scripting Interpreter | RCE via pickle/YAML/JSON deserialization        |
| Information disclosure   | **T1082** System Information Discovery      | Verbose errors, version leaks, debug mode       |
| Missing security headers | **T1525** Install Insecure Configuration    | CSP, HSTS, X-Frame-Options absent               |

## Common Weakness Enumeration (CWE)

Attach CWE IDs to findings for standardized classification:

| Finding Type                      | CWE     | Name                                             |
| --------------------------------- | ------- | ------------------------------------------------ |
| SQL injection                     | CWE-89  | SQL Injection                                    |
| XSS (reflected/stored)            | CWE-79  | Cross-site Scripting                             |
| XSS (DOM-based)                   | CWE-79  | Cross-site Scripting                             |
| Command injection                 | CWE-78  | OS Command Injection                             |
| Path traversal                    | CWE-22  | Path Traversal                                   |
| CSRF                              | CWE-352 | Cross-Site Request Forgery                       |
| SSRF                              | CWE-918 | Server-Side Request Forgery                      |
| IDOR                              | CWE-639 | Authorization Bypass Through User-Controlled Key |
| Broken access control             | CWE-862 | Missing Authorization                            |
| Incorrect authorization           | CWE-863 | Incorrect Authorization                          |
| Hardcoded credentials             | CWE-798 | Use of Hard-coded Credentials                    |
| Weak crypto                       | CWE-327 | Broken Cryptographic Algorithm                   |
| Missing encryption                | CWE-311 | Missing Encryption of Sensitive Data             |
| Insecure deserialization          | CWE-502 | Deserialization of Untrusted Data                |
| Open redirect                     | CWE-601 | URL Redirection to Untrusted Site                |
| Information exposure              | CWE-200 | Information Exposure                             |
| Session fixation                  | CWE-613 | Session Expiration Not Enforced                  |
| Insufficiently protected creds    | CWE-522 | Insufficiently Protected Credentials             |
| Origin validation error           | CWE-346 | Origin Validation Error                          |
| Uncontrolled resource consumption | CWE-400 | Uncontrolled Resource Consumption                |

## Chain Scoring

When combining findings into exploit chains, score each chain on five dimensions:

| Dimension       | Weight | What to Assess                                                                                      |
| --------------- | ------ | --------------------------------------------------------------------------------------------------- |
| **Reach**       | 30%    | How many users/systems can this chain reach? Single user vs all users vs infrastructure             |
| **Reliability** | 25%    | Does every step work reliably? Are there timing dependencies, race conditions, or fragile bypasses? |
| **Stealth**     | 20%    | Will this chain trigger WAF/IDS/SIEM detection? Rate limiting, log entries, network anomalies       |
| **Speed**       | 15%    | How quickly can the full chain execute? One-shot vs multi-step requiring user interaction           |
| **Impact**      | 10%    | What is the final business impact? Data exposure, account takeover, RCE, lateral movement           |

**Scoring:** Rate each dimension 1-5, multiply by weight, sum for total score. Chains scoring 4.0+ are Critical, 3.0-3.9 High, 2.0-2.9 Medium, below 2.0 Low.

Record chain scores in `memory.json` under `strategy` knowledge with the chain name, steps, and total score.

## Findings Database Integration

When `findings.db` exists in the workspace, use it as the authoritative data
source for findings queries.

### Querying for priority assessment

```bash
# All open findings sorted by severity
findings-web list-vulns ~/Documents/<target> --status open

# Critical and High findings requiring immediate attention
findings-web query ~/Documents/<target> "SELECT * FROM vulns WHERE severity IN ('Critical','High') AND status != 'false_positive' ORDER BY created DESC"

# Chains scored 4.0+ (Critical severity)
findings-web query ~/Documents/<target> "SELECT * FROM chains WHERE total_score >= 4.0"

# Credentials found across all hosts
findings-web query ~/Documents/<target> "SELECT c.*, h.hostname FROM credentials c JOIN hosts h ON c.host_id = h.id"
```

### Recording chain scores

After scoring a chain per the 5-dimension model above, insert it into the
`chains` table using `findings-web add-chain`. The `total_score` field
stores the weighted sum for automatic severity classification.
