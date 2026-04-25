{ mkWorkflow, securityAuditOutput, ... }:

mkWorkflow {
  useChangeControl = false;
  outputContract = securityAuditOutput;
  intro = ''
    Run a security audit with evidence only.

    Threat-modeling scope:
    - Inventory trust boundaries, entrypoints, secrets flow, privileged operations, network surfaces, external integrations, storage locations, CI/CD paths, update/install paths, and local execution hooks.
    - Adapt the threat model to the repo type rather than assuming a web app. Consider web, API, CLI, desktop/mobile, scripts, background jobs, containers, infrastructure as code, package publishing, and local automation surfaces as applicable.
  '';
  body = ''
    Audit checklist by evidence:
    - Authentication and authorization correctness.
    - Input handling, injection classes, command execution, unsafe eval, path traversal, SSRF, XSS, CSRF, open redirects, deserialization, and template injection where applicable.
    - Secrets management, credential exposure, token handling, and logging leaks.
    - Cryptography and randomness misuse.
    - File permissions, temp-file safety, unsafe shell usage, privilege escalation paths, and sandbox escape opportunities.
    - Dependency and supply-chain risks, CI workflow trust boundaries, release automation, and update/install integrity.
    - Container, IaC, and deployment posture where the repository owns those concerns.

    Reporting rules:
    - Prefer a smaller set of concrete findings over a generic checklist.
    - Rank severity using exploit preconditions, reachable attack path, privilege requirements, data sensitivity, and blast radius rather than the bug class name alone.
    - Group findings by trust boundary or attack surface when that makes the remediation path clearer.
    - Do not duplicate the same root cause across multiple findings unless the exploit surface is materially different.
    - If one root cause fans out into multiple sinks, report the shared root cause clearly and summarize the affected sinks without inflating the count.
    - When evidence is insufficient to prove a finding, downgrade it to a clearly labeled concern or gap rather than overstating it.
    - Distinguish confirmed vulnerabilities, likely weaknesses, and audit blind spots so remediation effort can be prioritized correctly.
  '';
}
