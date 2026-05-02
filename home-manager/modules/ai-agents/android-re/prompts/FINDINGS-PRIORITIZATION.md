# Findings Prioritization

## Adversarial Priority Order

Not all findings are equal. Prioritize by attacker impact — what can be exploited fastest with highest damage.

### 1. Secrets and Credentials (Instant Compromise)

**Why first:** No exploitation skill needed. Finding a hardcoded API key or auth token in source is a confirmed compromise.

**What to look for:**

- Hardcoded API keys in Java source (AWS, Stripe, Firebase, Google Maps, etc.)
- OAuth tokens or refresh tokens stored in SharedPreferences
- Encryption keys or signing keys in code
- Backend URLs with embedded credentials (`https://user:pass@api.internal.com`)
- `.env` files or config files with secrets in the APK assets
- Private keys in PEM/DER format in resources

**Action:** Report immediately. These are always EXPLOITABLE.

### 2. Input Validation Issues (High Exploitability)

**Why second:** Most common and directly exploitable. A SQL injection in a content provider or an XSS in a WebView is a working attack.

**What to look for:**

- SQL injection via content providers (`rawQuery` with concatenation)
- WebView XSS via JavaScript bridges or unvalidated URL loading
- Intent injection in exported components (extras used without validation)
- Deep link parameter injection (URL parameters used in sensitive operations)
- Path traversal (file paths from external input)
- Command injection (rare on Android but possible via `Runtime.exec`)

**Action:** Validate with dataflow framework. If source is attacker-controlled and component is exported, classify as EXPLOITABLE.

### 3. Authentication and Authorization (Access Control Failures)

**Why third:** Enables unauthorized access but may require more setup to exploit.

**What to look for:**

- Exported components without permission protection
- Missing authorization checks (any user can access any data)
- IDOR in content providers (sequential IDs, no ownership check)
- Weak or bypassable authentication (biometric bypass, PIN brute force)
- Session management issues (tokens not rotated, no logout invalidation)
- Signature permission bypass (if the signing key is compromised)

**Action:** Test with `am` commands from another app context. Verify if exported components enforce their declared permissions.

### 4. Cryptography Issues (Data Protection Failures)

**Why fourth:** Weakens data protection but usually requires chaining with another finding for exploitation.

**What to look for:**

- MD5 or SHA-1 used for password hashing or integrity checks
- Hardcoded encryption keys or IVs
- ECB mode for AES encryption (deterministic, pattern-leaking)
- Insecure key storage (keys in SharedPreferences instead of Android Keystore)
- Weak random number generation (`java.util.Random` instead of `SecureRandom`)
- SSL/TLS misconfigurations (custom TrustManager, cleartext traffic allowed)

**Action:** Document the weak crypto. Assess if it can be chained with a data access finding to decrypt sensitive information.

### 5. Configuration Issues (Security Baseline)

**Why last:** These are baseline problems that increase attack surface but are rarely directly exploitable alone.

**What to look for:**

- `android:allowBackup="true"` with sensitive data in local storage
- `android:debuggable="true"` in production builds
- Cleartext traffic allowed (`android:usesCleartextTraffic="true"`)
- Missing network security configuration
- Verbose logging of sensitive data (`Log.d` with tokens, passwords)
- Task hijacking (missing `android:taskAffinity=""` on login activities)
- Exported components that are not needed

**Action:** Document as configuration hardening recommendations. These inform the overall security posture.

## Severity Adjudication Process

For each validated finding, rate along four axes:

### Attack Prerequisites

| Level                  | Description                        | Examples                                      |
| ---------------------- | ---------------------------------- | --------------------------------------------- |
| **None**               | No prerequisites                   | Exported component, public content provider   |
| **User interaction**   | Requires user to perform an action | Click deep link, open file, grant permission  |
| **Specific app state** | Requires prior conditions          | User must be logged in, item must be selected |
| **Root or system**     | Requires elevated access           | Root access, system app, ADB shell            |

### Reachability

| Level                 | Description                     | Examples                               |
| --------------------- | ------------------------------- | -------------------------------------- |
| **Any app**           | Any third-party app             | Exported component with no permission  |
| **Permission holder** | Apps with a specific permission | Exported with `android:readPermission` |
| **Same signature**    | Only same-signer apps           | Signature-level permission             |
| **Internal only**     | Not exported, no deep link      | Private activity or service            |

### Data Sensitivity

| Level                  | Description                  | Examples                                         |
| ---------------------- | ---------------------------- | ------------------------------------------------ |
| **PII**                | Personally identifiable info | Name, email, phone, address, SSN                 |
| **Auth tokens**        | Session or auth credentials  | OAuth tokens, session cookies, API keys          |
| **Financial**          | Payment or financial data    | Credit card numbers, bank accounts, transactions |
| **Device identifiers** | Device-specific IDs          | IMEI, Android ID, advertising ID                 |
| **None**               | Non-sensitive data           | App preferences, UI state                        |

### Blast Radius

| Level             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| **Single user**   | Only affects the user of the compromised device        |
| **All users**     | Affects all users of the app (e.g., backend API issue) |
| **Device-level**  | Affects other apps or the device itself                |
| **Network-level** | Affects other devices or network services              |

## Severity Rating

Combine the four axes:

| Combination                                                                         | Severity          |
| ----------------------------------------------------------------------------------- | ----------------- |
| None prereqs + Any app reachability + PII/Auth/Financial + All users/Device/Network | **Critical**      |
| None prereqs + Any app reachability + Any sensitivity + Any blast radius            | **High**          |
| User interaction + Any app reachability + PII/Auth/Financial + Any blast radius     | **High**          |
| User interaction + Any reachability + Any sensitivity + Single user                 | **Medium**        |
| Specific app state or Permission holder reachability + Any sensitivity              | **Medium**        |
| Root required or Internal only + Any sensitivity                                    | **Low**           |
| Configuration hardening with no direct exploit path                                 | **Informational** |

## Upgrade and Downgrade Rules

**Upgrade when:**

- Finding can be chained with another finding to increase impact (e.g., IDOR + weak crypto = decrypt other users' data)
- The finding affects a high-value target (financial app, health app, enterprise app)
- The finding is easier to exploit than initial assessment suggested (e.g., root detection bypassed trivially)

**Downgrade when:**

- A confirmed effective mitigation exists on all paths (parameterized queries, strong CSP, proper output encoding)
- The source is confirmed not attacker-controlled after dataflow validation
- The component is not exported and has no deep link path
- The finding requires root access and the app is designed for rooted environments

**Mark as FALSE POSITIVE when:**

- Source is internal-only (hardcoded constants, server-computed values)
- Effective sanitizer exists on all paths with no known bypass
- Code path is unreachable (dead code, commented out, behind a false config flag)
- The "vulnerability" is intentional behavior (e.g., an auth endpoint that is supposed to be public)

## MITRE ATT&CK Mobile Mapping

Map every confirmed finding to the relevant ATT&CK Mobile technique:

| Priority Category              | ATT&CK Technique                            | Description                                                |
| ------------------------------ | ------------------------------------------- | ---------------------------------------------------------- |
| Secrets in local storage       | **T1530** Data from Local System            | Tokens/keys accessible in SharedPreferences, SQLite, files |
| Hardcoded secrets              | **T1552** Unsecured Credentials             | API keys, signing keys, backend URLs with creds in code    |
| SQL injection                  | **T1190** Exploit Public-Facing Application | Injection via exported content providers                   |
| Command injection              | **T1059** Command and Scripting Interpreter | `Runtime.exec` with attacker-controlled input              |
| Deep link abuse                | **T1407** / **T1412** via Application Data  | Malicious URIs triggering sensitive app flows              |
| WebView XSS                    | **T1477** Abuse Accessibility Features      | JS bridge exploitation for data access                     |
| Exported component abuse       | **T1525** Install Insecure Configuration    | Unprotected activities/services/receivers                  |
| Auth bypass                    | **T1078** Valid Accounts                    | Session reuse, token theft, credential stuffing            |
| Privilege escalation           | **T1548** Abuse Elevation Control Mechanism | IDOR, missing authorization checks                         |
| Weak crypto                    | **T1600** Weaken Encryption                 | ECB mode, hardcoded keys, MD5/SHA-1                        |
| Certificate pinning bypass     | **T1526** Install Root Certificate          | Custom CA injection, TrustManager bypass                   |
| Cleartext traffic              | **T1512** Downgrade to Insecure Protocol    | HTTP fallback, missing network security config             |
| Root/emulator detection bypass | **T1536** Exploit Vulnerability in App      | Anti-analysis circumvention enabling deeper access         |

## Common Weakness Enumeration (CWE)

Attach CWE IDs to findings for standardized classification:

| Finding Type                       | CWE     | Name                                        |
| ---------------------------------- | ------- | ------------------------------------------- |
| Hardcoded credentials              | CWE-798 | Use of Hard-coded Credentials               |
| Hardcoded crypto keys              | CWE-321 | Use of Hard-coded Cryptographic Key         |
| Cleartext storage                  | CWE-312 | Cleartext Storage of Sensitive Information  |
| Cleartext in memory                | CWE-316 | Cleartext Storage in Memory                 |
| SQL injection                      | CWE-89  | SQL Injection                               |
| XSS via WebView                    | CWE-79  | Cross-site Scripting                        |
| Intent injection                   | CWE-925 | Improper Intent Verification                |
| Exported components                | CWE-926 | Improper Export of Components               |
| Implicit intent for sensitive data | CWE-927 | Implicit Intent for Sensitive Communication |
| Path traversal                     | CWE-22  | Path Traversal                              |
| Command injection                  | CWE-78  | OS Command Injection                        |
| Weak crypto                        | CWE-327 | Broken Cryptographic Algorithm              |
| Insufficient randomness            | CWE-330 | Insufficient Random Values                  |
| Certificate validation bypass      | CWE-295 | Improper Certificate Validation             |
| Missing auth                       | CWE-287 | Improper Authentication                     |
| Missing authorization              | CWE-862 | Missing Authorization                       |
| Incorrect authorization            | CWE-863 | Incorrect Authorization                     |
| Insecure data storage (mobile)     | CWE-919 | Improper Storage of Sensitive Data          |
| Information exposure               | CWE-200 | Information Exposure                        |

## Chain Scoring

When combining findings into exploit chains, score each chain on five dimensions:

| Dimension       | Weight | What to Assess                                                                                      |
| --------------- | ------ | --------------------------------------------------------------------------------------------------- |
| **Reach**       | 30%    | How many users/systems can this chain reach? Single user vs all users vs device-level               |
| **Reliability** | 25%    | Does every step work reliably? Are there timing dependencies, race conditions, or fragile bypasses? |
| **Stealth**     | 20%    | Will this chain trigger detection? Log entries, network anomalies, app crashes                      |
| **Speed**       | 15%    | How quickly can the full chain execute? One-shot vs multi-step requiring user interaction           |
| **Impact**      | 10%    | What is the final business impact? Data exposure, account takeover, code execution                  |

**Scoring:** Rate each dimension 1-5, multiply by weight, sum for total score. Chains scoring 4.0+ are Critical, 3.0-3.9 High, 2.0-2.9 Medium, below 2.0 Low.

Record chain scores in `memory.json` under `strategy` knowledge with the chain name, steps, and total score.

## Findings Database Integration

When `findings.db` exists in the workspace, use it as the authoritative data
source for findings queries.

### Querying for priority assessment

```bash
# All open findings sorted by severity
findings-android list-vulns ~/Documents/<target> --status open

# Critical and High findings requiring immediate attention
findings-android query ~/Documents/<target> "SELECT * FROM vulns WHERE severity IN ('Critical','High') AND status != 'false_positive' ORDER BY created DESC"

# Chains scored 4.0+ (Critical severity)
findings-android query ~/Documents/<target> "SELECT * FROM chains WHERE total_score >= 4.0"

# Credentials found across all hosts
findings-android query ~/Documents/<target> "SELECT c.*, h.hostname FROM credentials c JOIN hosts h ON c.host_id = h.id"
```

### Recording chain scores

After scoring a chain per the 5-dimension model above, insert it into the
`chains` table using `findings-android add-chain`. The `total_score` field
stores the weighted sum for automatic severity classification.
