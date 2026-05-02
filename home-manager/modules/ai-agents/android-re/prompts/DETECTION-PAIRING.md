# Detection Pairing

## Why Pair Detection with Findings

Every confirmed vulnerability should ship with detection content that defenders can deploy immediately. A finding without detection guidance is a point-in-time observation that evaporates once the engagement ends. Detection pairing ensures:

- defenders can monitor for exploitation of the vulnerabilities you discovered
- findings map to observable indicators in log sources defenders already collect
- the engagement delivers lasting defensive value, not just a vulnerability list
- blue teams can validate remediation by confirming detection alerts fire correctly

Detection content is mandatory for every finding with confidence >= "likely" (see FINDINGS-PRIORITIZATION.md severity adjudication and SESSION-MEMORY.md confidence scoring >= 0.5).

## Required Detection Content

For every confirmed finding (confidence >= "likely"), produce at minimum one of the following detection artifacts. Critical and High severity findings require at least two detection types.

### YARA Rules

YARA rules detect malicious patterns in files, memory dumps, and APK artifacts. Use them for static indicators found during analysis.

**Template:**

```yara
rule <Category>_<ShortDescription> {
    meta:
        description = "<What this rule detects>"
        author = "Android RE Agent"
        date = "<YYYY-MM-DD>"
        severity = "<Critical|High|Medium|Low>"
        reference = "<finding_id or URL>"
        target_package = "<com.example.app>"

    strings:
        $s1 = "<pattern>" ascii wide
        $s2 = "<pattern>" ascii wide

    condition:
        any of them
}
```

**Android examples:**

```yara
rule Android_HardcodedAPIKey_Google {
    meta:
        description = "Detects hardcoded Google API keys in APK resources or source"
        severity = "High"
        reference = "CWE-798"

    strings:
        $key_aiza = /AIza[0-9A-Za-z\-_]{35}/ ascii wide
        $key_google_places = /AIza[0-9A-Za-z\-_]{35}/ ascii wide

    condition:
        any of them
}

rule Android_WeakCrypto_ECB_AES {
    meta:
        description = "Detects AES/ECB cipher usage in Java source"
        severity = "High"
        reference = "CWE-327"

    strings:
        $ecb1 = "AES/ECB/" ascii
        $ecb2 = "AES/ECB/PKCS5Padding" ascii wide
        $ecb3 = "AES/ECB/NoPadding" ascii wide

    condition:
        any of them
}

rule Android_CertPinningBypass_CustomTrustManager {
    meta:
        description = "Detects custom TrustManager implementations that accept all certificates"
        severity = "Critical"
        reference = "CWE-295"

    strings:
        $tm1 = "X509TrustManager" ascii
        $tm2 = "checkServerTrusted" ascii
        $tm3 = "return null" ascii
        $tm4 = " TrustManager[] " ascii

    condition:
        $tm1 and $tm2 and ($tm3 or $tm4)
}

rule Android_RootDetectionBypass {
    meta:
        description = "Detects root detection bypass patterns in Frida scripts or modified APKs"
        severity = "High"
        reference = "T1536"

    strings:
        $root1 = "File.exists" ascii
        $root2 = "/system/app/Superuser.apk" ascii wide
        $root3 = "/sbin/su" ascii wide
        $root4 = "/system/bin/su" ascii wide
        $root5 = "isDeviceRooted" ascii
        $root6 = "RootBeer" ascii

    condition:
        2 of them
}

rule Android_EmulatorDetectionBypass {
    meta:
        description = "Detects emulator detection bypass code targeting Android emulators"
        severity = "Medium"
        reference = "T1536"

    strings:
        $emu1 = "goldfish" ascii
        $emu2 = "ro.kernel.qemu" ascii
        $emu3 = "ro.hardware.chipname" ascii
        $emu4 = "init.svc.qemud" ascii
        $emu5 = "ro.product.model" ascii wide
        $emu6 = "sdk_gphone" ascii wide

    condition:
        2 of ($emu1, $emu2, $emu3, $emu4) or any of ($emu5, $emu6)
}
```

### Sigma Rules

Sigma rules detect suspicious behavior in Android system logs and security tool outputs. Convert them to the target SIEM query language for deployment.

**Template:**

```yaml
title: <Short Description>
id: <uuid>
status: experimental
description: <What this rule detects>
references:
  - <finding_id or URL>
author: Android RE Agent
date: <YYYY-MM-DD>
tags:
  - attack.execution
  - attack.t1xxx
logsource:
  product: android
  service: <logcat|dumpsys|logreader>
detection:
  selection:
    <field>|<modifier>:
      - <value>
  condition: selection
falsepositives:
  - <legitimate scenarios that trigger this rule>
level: <critical|high|medium|low>
```

**Android examples:**

```yaml
title: Suspicious Intent Dispatch to Exported Component
id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
status: experimental
description: >
  Detects adb shell am commands or third-party app intents targeting exported
  components without proper permission enforcement
references:
  - CWE-926
author: Android RE Agent
date: 2025-01-15
tags:
  - attack.execution
  - attack.t1525
logsource:
  product: android
  service: logcat
detection:
  selection:
    tag|contains:
      - "ActivityManager"
    message|contains|all:
      - "START"
      - "android.content.Intent"
  filter_am_start:
    message|contains:
      - "am start"
      - "am broadcast"
      - "am startservice"
  filter_exported:
    message|contains:
      - "exported=true"
      - "permission=null"
  condition: selection and filter_am_start and filter_exported
falsepositives:
  - Legitimate testing with adb during development
  - Automation frameworks exercising app components
level: high
```

```yaml
title: Content Provider Abuse via SQL Injection
id: b2c3d4e5-f6a7-8901-bcde-f12345678901
status: experimental
description: >
  Detects SQL injection attempts against exported content providers
  identified via content query commands
references:
  - CWE-89
author: Android RE Agent
date: 2025-01-15
tags:
  - attack.execution
  - attack.t1190
logsource:
  product: android
  service: logcat
detection:
  selection:
    tag|contains:
      - "ContentProvider"
      - "DatabaseHelper"
  keywords:
    message|contains:
      - "UNION SELECT"
      - "OR 1=1"
      - "' OR '"
      - "-- "
      - "FROM sqlite_master"
  condition: selection and keywords
falsepositives:
  - Debug logging of legitimate complex queries
level: critical
```

```yaml
title: Exported Component Invocation from Untrusted Package
id: c3d4e5f6-a7b8-9012-cdef-123456789012
status: experimental
description: >
  Detects when an untrusted (non-system, non-self) package invokes
  an exported component on the target app
author: Android RE Agent
date: 2025-01-15
tags:
  - attack.execution
  - attack.t1525
logsource:
  product: android
  service: dumpsys
detection:
  selection:
    component|contains:
      - "<target_package>"
  caller:
    calling_package|ne:
      - "<target_package>"
      - "android"
      - "com.android.systemui"
  condition: selection and caller
falsepositives:
  - Legitimate intent sharing from other apps
  - System-level component invocations
level: medium
```

```yaml
title: Frida Instrumentation Attachment
id: d4e5f6a7-b8c9-0123-defa-234567890123
status: experimental
description: >
  Detects Frida server or Frida instrumentation attached to the target
  application process
author: Android RE Agent
date: 2025-01-15
tags:
  - attack.defense_evasion
  - attack.t1536
logsource:
  product: android
  service: logcat
detection:
  selection_frida:
    message|contains:
      - "frida-server"
      - "frida-agent"
      - "linjector"
      - "re.frida.server"
  selection_port:
    message|contains:
      - "27042"
  selection_tmp:
    message|contains:
      - "/tmp/frida-"
      - "/data/local/tmp/frida"
      - "/data/local/tmp/re.frida.server"
  condition: selection_frida or selection_port or selection_tmp
falsepositives:
  - Authorized security testing with Frida
  - Development debugging sessions
level: high
```

### Network IOC Patterns

Network IOCs identify compromised API endpoints, anomalous backend traffic, and data exfiltration indicators from Android app network communication.

**Template:**

```json
{
  "type": "network_ioc",
  "finding_id": "<FIND-001>",
  "category": "<compromised_endpoint|anomalous_traffic|callback_exfil|dns_exfiltration>",
  "indicators": {
    "domains": [],
    "ips": [],
    "urls": [],
    "patterns": []
  },
  "description": "<What this IOC detects>",
  "severity": "<Critical|High|Medium|Low>",
  "traffic_direction": "<inbound|outbound|bidirectional>",
  "protocols": ["<http|https|tcp|udp|dns|websocket>"],
  "log_sources": ["<mitmproxy|burp|pcap|firewall|dns_resolver>"]
}
```

**Android examples:**

```json
{
  "type": "network_ioc",
  "finding_id": "FIND-003",
  "category": "anomalous_traffic",
  "indicators": {
    "domains": ["api.internal-staging.example.com"],
    "urls": ["/api/v2/users/export"],
    "patterns": ["Content-Type: application/octet-stream", "X-Debug-Mode: true"]
  },
  "description": "App communicates with internal staging API endpoint, exposing debug headers that reveal server internals",
  "severity": "High",
  "traffic_direction": "outbound",
  "protocols": ["https"],
  "log_sources": ["mitmproxy", "pcap"]
}
```

```json
{
  "type": "network_ioc",
  "finding_id": "FIND-007",
  "category": "callback_exfil",
  "indicators": {
    "domains": ["analytics.thirdparty.net"],
    "urls": ["/collect"],
    "patterns": ["android_id=", "imei=", "advertising_id=", "email="]
  },
  "description": "App sends device identifiers and user email to third-party analytics without consent disclosure",
  "severity": "Medium",
  "traffic_direction": "outbound",
  "protocols": ["https"],
  "log_sources": ["mitmproxy", "pcap"]
}
```

```json
{
  "type": "network_ioc",
  "finding_id": "FIND-012",
  "category": "compromised_endpoint",
  "indicators": {
    "domains": [],
    "urls": ["/api/v1/reset-password"],
    "patterns": ["HTTP/1.1 200", "new_password="]
  },
  "description": "Password reset endpoint returns new password in cleartext response instead of sending via email",
  "severity": "Critical",
  "traffic_direction": "inbound",
  "protocols": ["https"],
  "log_sources": ["mitmproxy", "burp"]
}
```

### Log Source Recommendations

Android-specific log sources and filters for detecting exploitation of confirmed findings.

**Logcat filters:**

```bash
# Monitor exported component invocations
adb logcat -s ActivityManager:I | grep -E 'START|BIND|ContentProvider'

# Detect SQL injection attempts against content providers
adb logcat -s SQLiteLog:E | grep -E 'syntax error|unrecognized token|near "'

# Monitor NetworkSecurityConfig violations
adb logcat -s NetworkSecurityConfig:* | grep -E 'cleartext|Cleartext traffic|permitted'

# Detect certificate validation failures
adb logcat | grep -E 'SSLHandshakeException|CertPathValidatorException|CertificateException'

# Monitor debug/verbose logging of sensitive data
adb logcat -s '*:D' '*:V' | grep -iE 'token|password|key|secret|session|auth'

# Track intent delivery to target package
adb logcat | grep -E 'Intent.*com.example.target|BroadcastQueue.*com.example.target'
```

**Dumpsys patterns:**

```bash
# Enumerate exported components and their permissions
adb shell dumpsys package com.example.target | grep -A5 'exported=true'

# Check recent intent deliveries
adb shell dumpsys activity intents | grep com.example.target

# Review content provider grants
adb shell dumpsys content | grep com.example.target

# Verify NetworkSecurityConfig
adb shell dumpsys netstats | grep com.example.target
```

**NetworkSecurityConfig violations:**

```bash
# Monitor cleartext traffic violations
adb logcat -s NetworkSecurityConfig:* | grep 'Cleartext traffic'

# Check for missing or misconfigured network security config
adb shell cat /data/data/com.example.target/network_security_config.xml 2>/dev/null

# Verify certificate pinning enforcement
adb logcat | grep -E 'CertificatePinner|PinningCheck|Pinner'
```

## Integration Points

- **EXPLOIT-VERIFICATION.md**: Level 3+ confirmed findings (EXPLOITED and EXPLOITED CRITICAL) require detection content before session close. Level 4 findings require all four detection types.
- **FINDINGS-PRIORITIZATION.md**: Detection content severity should match the finding severity from the adversarial priority order. Critical and High findings require YARA + Sigma at minimum.
- **FINDINGS-DB.md**: Store detection content in the `detection_yara`, `detection_sigma`, `detection_network`, and `detection_siem` columns of the `vulns` table. This makes detection queryable alongside finding metadata.
- **SESSION-MEMORY.md**: Record effective detection patterns as `tool_config` knowledge so future sessions can reuse them across targets sharing similar vulnerability classes.
- **WORKFLOW.md**: Phase 10 (Confidence and Chaining Review) is the trigger point for writing detection content. Do not defer detection pairing past session close.
