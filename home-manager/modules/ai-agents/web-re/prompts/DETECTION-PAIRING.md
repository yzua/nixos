# Detection Pairing

## Why Pair Detection with Findings

Every confirmed vulnerability should ship with detection content that defenders can deploy immediately. A finding without detection guidance is a point-in-time observation that evaporates once the engagement ends. Detection pairing ensures:

- defenders can monitor for exploitation of the vulnerabilities you discovered
- findings map to observable indicators in WAF logs, access logs, and SIEM dashboards
- the engagement delivers lasting defensive value, not just a vulnerability list
- blue teams can validate remediation by confirming detection alerts fire correctly

Detection content is mandatory for every finding with confidence >= "likely" (see FINDINGS-PRIORITIZATION.md severity adjudication and SESSION-MEMORY.md confidence scoring >= 0.5).

## Required Detection Content

For every confirmed finding (confidence >= "likely"), produce at minimum one of the following detection artifacts. Critical and High severity findings require at least two detection types.

### YARA Rules

YARA rules detect malicious patterns in JavaScript files, server logs, and web application source. Use them for payload patterns found in request logs and static assets.

**Template:**

```yara
rule <Category>_<ShortDescription> {
    meta:
        description = "<What this rule detects>"
        author = "Web RE Agent"
        date = "<YYYY-MM-DD>"
        severity = "<Critical|High|Medium|Low>"
        reference = "<finding_id or URL>"
        target = "<target domain>"

    strings:
        $s1 = "<pattern>" ascii wide
        $s2 = "<pattern>" ascii wide

    condition:
        any of them
}
```

**Web-focused examples:**

```yara
rule Web_XSS_ReflectedPayload_JavaScript {
    meta:
        description = "Detects reflected XSS payload patterns in JavaScript source and request logs"
        severity = "High"
        reference = "CWE-79"

    strings:
        $xss1 = "<script>" ascii nocase
        $xss2 = "javascript:" ascii nocase
        $xss3 = "onerror=" ascii nocase
        $xss4 = "onload=" ascii nocase
        $xss5 = "document.cookie" ascii nocase
        $xss6 = "alert(" ascii
        $xss7 = "document.location" ascii nocase
        $xss8 = ".innerHTML" ascii

    condition:
        2 of them
}

rule Web_SQLi_RequestLog_Patterns {
    meta:
        description = "Detects SQL injection patterns in HTTP request log files"
        severity = "Critical"
        reference = "CWE-89"

    strings:
        $sqli1 = "' OR '1'='1" ascii nocase
        $sqli2 = "UNION SELECT" ascii nocase
        $sqli3 = "' UNION ALL SELECT" ascii nocase
        $sqli4 = "FROM information_schema" ascii nocase
        $sqli5 = "SLEEP(" ascii nocase
        $sqli6 = "BENCHMARK(" ascii nocase
        $sqli7 = "WAITFOR DELAY" ascii nocase
        $sqli8 = "' AND 1=1--" ascii nocase
        $sqli9 = "pg_sleep(" ascii nocase

    condition:
        2 of them
}

rule Web_SSRF_Callback_Pattern {
    meta:
        description = "Detects SSRF callback URL patterns in request logs indicating internal service access"
        severity = "Critical"
        reference = "CWE-918"

    strings:
        $ssrf1 = "169.254.169.254" ascii
        $ssrf2 = "metadata.google.internal" ascii
        $ssrf3 = "http://127.0.0.1" ascii
        $ssrf4 = "http://localhost" ascii nocase
        $ssrf5 = "http://10." ascii
        $ssrf6 = "http://192.168." ascii
        $ssrf7 = "http://172.16." ascii
        $ssrf8 = "gopher://" ascii
        $ssrf9 = "dict://" ascii

    condition:
        any of them
}
```

### Sigma Rules

Sigma rules detect web attack patterns in server access logs, application logs, and WAF logs. Convert them to the target SIEM query language for deployment.

**Template:**

```yaml
title: <Short Description>
id: <uuid>
status: experimental
description: <What this rule detects>
references:
  - <finding_id or URL>
author: Web RE Agent
date: <YYYY-MM-DD>
tags:
  - attack.initial_access
  - attack.t1xxx
logsource:
  category: <webserver|application|proxy>
  product: <nginx|apache|iis|burp|waf>
detection:
  selection:
    <field>|<modifier>:
      - <value>
  condition: selection
falsepositives:
  - <legitimate scenarios that trigger this rule>
level: <critical|high|medium|low>
```

**Web-focused examples:**

```yaml
title: SQL Injection Attempt in Web Server Access Logs
id: e5f6a7b8-c9d0-1234-efab-345678901234
status: experimental
description: >
  Detects common SQL injection payload patterns in HTTP request URIs
  and query parameters from web server access logs
references:
  - CWE-89
author: Web RE Agent
date: 2025-01-15
tags:
  - attack.initial_access
  - attack.t1190
logsource:
  category: webserver
detection:
  selection_uri:
    cs-uri-query|contains:
      - "' OR '"
      - "' AND '"
      - "UNION SELECT"
      - "UNION ALL SELECT"
      - "information_schema"
      - "SLEEP("
      - "BENCHMARK("
      - "WAITFOR DELAY"
      - "pg_sleep("
      - "'; DROP TABLE"
  selection_body:
    cs-body|contains:
      - "' OR '"
      - "UNION SELECT"
      - "SLEEP("
  condition: selection_uri or selection_body
falsepositives:
  - Legitimate queries containing mathematical expressions that resemble SQLi
  - Security scanners performing authorized vulnerability scanning
level: high
```

```yaml
title: XSS Attempt in Access Logs
id: f6a7b8c9-d0e1-2345-fabc-456789012345
status: experimental
description: >
  Detects cross-site scripting payload patterns in HTTP request parameters
  and request bodies
references:
  - CWE-79
author: Web RE Agent
date: 2025-01-15
tags:
  - attack.initial_access
  - attack.t1189
logsource:
  category: webserver
detection:
  selection:
    cs-uri-query|contains:
      - "<script>"
      - "javascript:"
      - "onerror="
      - "onload="
      - "onmouseover="
      - "document.cookie"
      - "alert("
      - "prompt("
      - "confirm("
      - "String.fromCharCode("
  condition: selection
falsepositives:
  - Legitimate JavaScript frameworks using similar patterns in URL parameters
  - WAF testing tools
level: medium
```

```yaml
title: SSRF Attempt Targeting Internal or Cloud Resources
id: a7b8c9d0-e1f2-3456-abcd-567890123456
status: experimental
description: >
  Detects server-side request forgery attempts targeting internal network
  addresses, cloud metadata endpoints, or alternative protocols
references:
  - CWE-918
author: Web RE Agent
date: 2025-01-15
tags:
  - attack.initial_access
  - attack.t1190
logsource:
  category: proxy
detection:
  selection:
    cs-uri|contains:
      - "169.254.169.254"
      - "metadata.google.internal"
      - "http://127.0.0.1"
      - "http://localhost"
      - "http://10."
      - "http://192.168."
      - "http://172.16."
      - "http://172.17."
      - "http://172.18."
      - "http://172.19."
      - "http://172.2"
      - "http://172.3"
      - "gopher://"
      - "dict://"
      - "file:///"
  condition: selection
falsepositives:
  - Internal health check endpoints
  - Monitoring systems probing internal services
level: critical
```

```yaml
title: Authentication Bypass via Token Manipulation
id: b8c9d0e1-f2a3-4567-bcde-678901234567
status: experimental
description: >
  Detects authentication bypass attempts including JWT manipulation,
  session token reuse, and authorization header anomalies
references:
  - CWE-287
author: Web RE Agent
date: 2025-01-15
tags:
  - attack.defense_evasion
  - attack.t1078
logsource:
  category: application
detection:
  selection_jwt:
    cs-authorization|contains:
      - "eyJhbGciOiJub25lIn0"
      - "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
  selection_role:
    cs-body|contains:
      - '"role":"admin"'
      - '"role":"administrator"'
      - '"isAdmin":true'
      - '"is_admin":true'
  selection_none:
    cs-authorization|contains:
      - ".eyJ"
      - "alg:none"
  condition: selection_jwt or selection_role or selection_none
falsepositives:
  - Legitimate admin users performing normal operations
  - Token refresh operations
level: high
```

### Network IOC Patterns

Network IOCs identify HTTP callback patterns, DNS exfiltration, anomalous user-agent strings, and suspicious traffic from web application exploitation.

**Template:**

```json
{
  "type": "network_ioc",
  "finding_id": "<FIND-001>",
  "category": "<http_callback|dns_exfiltration|anomalous_ua|beaconing|data_staging>",
  "indicators": {
    "domains": [],
    "ips": [],
    "urls": [],
    "user_agents": [],
    "patterns": []
  },
  "description": "<What this IOC detects>",
  "severity": "<Critical|High|Medium|Low>",
  "traffic_direction": "<inbound|outbound|bidirectional>",
  "protocols": ["<http|https|dns|tcp|udp>"],
  "log_sources": ["<access_log|waf|dns_resolver|pcap|proxy>"]
}
```

**Web-focused examples:**

```json
{
  "type": "network_ioc",
  "finding_id": "FIND-005",
  "category": "http_callback",
  "indicators": {
    "domains": ["evil-callback.attacker.com"],
    "urls": ["/collect?d="],
    "patterns": ["Cookie: session=", "GET /collect?d=eyJ"]
  },
  "description": "XSS payload triggers HTTP callback with stolen session cookies to attacker-controlled domain",
  "severity": "Critical",
  "traffic_direction": "outbound",
  "protocols": ["https"],
  "log_sources": ["access_log", "proxy", "waf"]
}
```

```json
{
  "type": "network_ioc",
  "finding_id": "FIND-008",
  "category": "dns_exfiltration",
  "indicators": {
    "domains": [],
    "patterns": [
      "[a-zA-Z0-9]{32,}\\.(data|exfil)\\.",
      ".*\\.c2\\.attacker\\.net$",
      "response length > 100 chars in TXT record query"
    ]
  },
  "description": "SQL injection exfiltrates data via DNS TXT queries with encoded database contents as subdomains",
  "severity": "Critical",
  "traffic_direction": "outbound",
  "protocols": ["dns"],
  "log_sources": ["dns_resolver", "pcap"]
}
```

```json
{
  "type": "network_ioc",
  "finding_id": "FIND-011",
  "category": "anomalous_ua",
  "indicators": {
    "user_agents": [
      "sqlmap/1.*",
      "Nikto/2.*",
      "Nuclei/*",
      "Python-urllib/*",
      "Go-http-client/*"
    ]
  },
  "description": "Automated scanning tools with identifiable user-agent strings hitting target endpoints",
  "severity": "Medium",
  "traffic_direction": "inbound",
  "protocols": ["http", "https"],
  "log_sources": ["access_log", "waf"]
}
```

### SIEM Queries

Ready-to-deploy SIEM queries for Splunk SPL and Elastic KQL. Adapt field names to match the target's log format.

**Splunk SPL templates:**

```spl
-- SQL Injection detection
index=web sourcetype=access_log
  (cs_uri_query="*UNION*" OR cs_uri_query="*SELECT*" OR cs_uri_query="*SLEEP*" OR cs_uri_query="*' OR*")
  | stats count by src_ip, cs_uri_query, cs_uri_stem
  | where count > 5
  | sort -count

-- XSS detection
index=web sourcetype=access_log
  (cs_uri_query="*<script>*" OR cs_uri_query="*javascript:*" OR cs_uri_query="*onerror=*")
  | stats count by src_ip, cs_uri_stem, cs_uri_query
  | sort -_time

-- SSRF detection
index=web sourcetype=access_log OR sourcetype=proxy_log
  (cs_uri_stem="*169.254.169.254*" OR cs_uri_stem="*metadata.google.internal*" OR cs_uri_stem="*127.0.0.1*")
  | stats count by src_ip, cs_uri_stem, sc_status
  | sort -count

-- Auth bypass detection
index=web sourcetype=access_log
  cs_authorization="*eyJhbGciOiJub25lIn0*"
  | stats count by src_ip, cs_uri_stem, cs_authorization
  | sort -_time

-- Brute force detection
index=web sourcetype=access_log cs_uri_stem="/api/auth/login" sc_status=401
  | stats count as failed_attempts by src_ip
  | where failed_attempts > 10
  | sort -failed_attempts
```

**Elastic KQL templates:**

```kql
-- SQL Injection detection
url.query: ("UNION" OR "SELECT" OR "SLEEP" OR "' OR" OR "information_schema") AND http.request.method: ("GET" OR "POST")

-- XSS detection
url.query: ("<script>" OR "javascript:" OR "onerror=" OR "onload=" OR "document.cookie")

-- SSRF detection
url.full: ("169.254.169.254" OR "metadata.google.internal" OR "127.0.0.1" OR "gopher://" OR "dict://")

-- Auth bypass detection
http.request.headers.authorization: ("eyJhbGciOiJub25lIn0" OR "alg:none") OR http.request.body.content: ("role:admin" OR "isAdmin:true")

-- Rate limiting violation
url.path: "/api/auth/login" AND http.response.status_code: 401 AND event.outcome: "failure"
```

## Integration Points

- **EXPLOIT-VERIFICATION.md**: Level 3+ confirmed findings (EXPLOITED and EXPLOITED CRITICAL) require detection content before session close. Level 4 findings require all four detection types.
- **FINDINGS-PRIORITIZATION.md**: Detection content severity should match the finding severity from the adversarial priority order. Critical and High findings require YARA + Sigma at minimum.
- **FINDINGS-DB.md**: Store detection content in the `detection_yara`, `detection_sigma`, `detection_network`, and `detection_siem` columns of the `vulns` table. This makes detection queryable alongside finding metadata.
- **SESSION-MEMORY.md**: Record effective detection patterns as `tool_config` knowledge so future sessions can reuse them across targets sharing similar vulnerability classes.
- **WORKFLOW.md**: Phase 9 (Confidence Review) is the trigger point for writing detection content. Do not defer detection pairing past session close.
