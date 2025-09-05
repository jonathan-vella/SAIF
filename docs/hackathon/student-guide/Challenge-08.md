---
version: 1.1.0
last_updated: 2025-09-04
guide_type: student
challenge: 08
title: Defender for Containers – Hardening SAIF Container Supply Chain (v2 Only)
---

# Challenge 08: Defender for Containers – Hardening SAIF Container Supply Chain (v2)

## Objective
Enable Microsoft Defender plans relevant to SAIF v2 (Containers + App Service), baseline image vulnerabilities in Azure Container Registry (ACR), prioritize and remediate high‑risk findings **without modifying application logic**, and prove risk reduction (before vs after evidence).

## Scenario
SAIF v2 runs two Linux containers (API: Python / Web: PHP) on Azure App Service pulling images from ACR. There is **no AKS cluster in the base environment**. Your focus is the container supply chain and runtime configuration surface exposed via App Service. Defender for Containers provides registry image scanning and threat detection; Defender for App Service adds additional posture & runtime signals.

You must:
1. Enable the appropriate Defender plan(s)
2. Collect a baseline vulnerability inventory for both images
3. Prioritize vulnerabilities (risk-based, not raw counts)
4. Perform minimal, safe image hardening (base image updates, removing unused packages) – no functional feature changes
5. Rebuild & push images, redeploy automatically via App Service pull
6. Demonstrate measurable improvement & document residual risk

## Learning Outcomes
- Understand Defender for Cloud integration points with ACR + App Service
- Differentiate image **risk triage** vs “patch everything” anti‑pattern
- Apply immutable tagging concepts (digest vs mutable latest)
- Produce actionable remediation evidence for stakeholders
- Plan next‑step supply chain enhancements (SBOM, policy gates)

## Constraints
- Do **not** rewrite application code or remove intentionally vulnerable API endpoints.
- Keep educational vulnerabilities (broad diagnostics, permissive CORS) intact.
- Focus on container hygiene & patch strategy.

## Timeline & Milestones
| Suggested Duration | Milestone                                    |
|--------------------|-----------------------------------------------|
| 15 min             | Defender plans enabled & verified             |
| 20 min             | Baseline vulnerability inventory captured     |
| 15 min             | Prioritization + remediation plan drafted     |
| 10–20 min          | Rebuild, push, redeploy & capture improvements|

## Phased Instructions

### Phase 1 – Enable & Verify Defender Plans
1. Enable Microsoft Defender for Containers (covers ACR scanning) and Defender for App Service (optional but recommended for breadth).
2. Confirm ACR shows vulnerability assessment (portal or CLI).
3. Capture evidence (screenshot or CLI output).

### Phase 2 – Baseline Vulnerability Inventory
1. List images & digests: `saifv2/api:latest`, `saif/web:latest`.
2. Retrieve vulnerability findings (portal export, REST, or continuous export to Log Analytics if configured).
3. Tally counts by severity (Critical / High / Medium / Low) and identify Top 5 (package, version, CVE, severity, fix available?).

### Phase 3 – Prioritize & Plan
Use a risk lens:
- Exploitability (public exploits, high EPSS, or known weaponization)
- Exposure (network-facing runtime package vs build-time only)
- Fix availability & upgrade complexity
- Chaining potential (e.g., outdated OpenSSL + permissive outbound)
Document a short table: Rank | CVE | Package | Justification | Action.

### Phase 4 – Remediate (Minimal Hardening)
Apply only safe changes:
- Update base image tags to latest patch release (e.g., `php:8.2-apache` -> newer digest)
- Run security updates (`apt-get update && apt-get dist-upgrade -y && apt-get clean`)
- Remove unused build tools after installation
- Avoid pinning to vulnerable minors; prefer secure patch tag or digest
Note: Keep app logic & vulnerable endpoints unchanged (training requirement).

### Phase 5 – Rebuild & Redeploy
1. Rebuild images and push (existing automation scripts acceptable).
2. Confirm new digests in ACR and that App Services pulled updates (portal or `az webapp show` siteConfig linuxFxVersion).
3. Optionally force a restart to accelerate image pull if needed.

### Phase 6 – Validate Improvement
1. Re-run vulnerability assessment (wait for scan completion; note possible delay).
2. Produce before vs after table (Critical/High/Medium counts delta).
3. Capture new Top 5 (if any) and rationale why remaining issues were deferred (e.g., library EOL, no patch yet, low exploitability).

### Stretch Goals (Optional)
- Pin deployments to **image digests** instead of mutable `latest`.
- Draft a CI gate concept: block if Critical > 0 OR High > N.
- Outline future SBOM / attestation (Notation, Artifact Manifest) plan.
- KQL dashboard for vulnerability trend (simulated if export not enabled).

### Evidence Checklist
- Defender plan(s) enabled (screenshot or CLI JSON excerpt)
- Initial severity distribution & Top 5 table
- Prioritization matrix with justification
- Remediation actions (concise list of Dockerfile / layer changes)
- New image digests & App Service runtime config showing updated FxVersion
- Post-remediation scan results & delta table
- Reflection: residual risks + next recommended steps

### Sample Tables
Baseline Severity Distribution:

| Severity | Count | Notes |
|----------|-------|-------|
| Critical |  X    | 2 in base image layer |
| High     |  Y    | Majority from outdated system packages |
| Medium   |  Z    | ... |
| Low      |  W    | ... |

Prioritization (Example):
| Rank | CVE | Package | Sev | Justification | Planned Action |
|------|-----|---------|-----|---------------|----------------|
| 1 | CVE-XXXX | openssl | High | Network exposed TLS | Update via base image patch |

### Optional KQL Snippets (if continuous export configured)
```kql
// Defender for Cloud container image findings (example placeholder)
SecurityResourceVulnerabilities
| where ResourceId has "Microsoft.ContainerRegistry"
| summarize count() by Severity = tostring(Properties.Severity)
```

## Rubric (Revised)

## Quality Checklist
- Defender plans enabled with evidence (JSON excerpt or screenshot).
- Baseline + post-remediation severity distribution captured.
- Top 5 vulnerabilities prioritized with clear justification.
- Remediation limited to safe hygiene (no app logic changes).
- Before/after digest and vulnerability delta documented.
- Residual risks + next steps explicitly stated.

See consolidated checklist: [QUALITY-CHECKLIST](../QUALITY-CHECKLIST.md#challenge-08--defender-for-containers--supply-chain)

### Submission Artifacts
- Plan enablement evidence
- Baseline & post-remediation tables
- Prioritization matrix
- Remediation change summary
- Delta (before vs after) & residual risk notes
| Criteria | Points | Description |
|----------|--------|-------------|
| Defender Plans Enabled & Verified | 15 | Containers + (optionally) App Service plan active, evidence provided |
| Baseline Vulnerability Inventory | 15 | Clear severity distribution + Top 5 table |
| Risk Prioritization & Justification | 15 | Rationale ties to exploitability/exposure/fix availability |
| Effective Remediation Execution | 25 | High/Critical reduced or justified; safe minimal changes |
| Supply Chain Hardening Actions | 15 | At least two (digest pin, package cleanup, minimized layers, tagging strategy) |
| Evidence & Improvement Delta | 10 | Before/after comparison + digest proof |
| Reflection & Next Steps | 5 | Residual risk + forward plan (policy, CI gate, SBOM) |
| **Total** | **100** |  |

**Notes:**
- Do not remove intentional training vulnerabilities at the application layer.
- Partial credit available if scans delayed (must document attempt + pending state).

## Common Pitfalls
| Pitfall | Impact | Mitigation |
|---------|--------|------------|
| Chasing all lows | Wasted time | Focus on exploitable + high impact |
| Over-hardening (breaking app) | Lost training value | Limit to patch & hygiene changes |
| Relying on tag `latest` | Deployment drift | Record & (optionally) use digest |

## References
- [Defender for Containers Introduction](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-introduction)
- [Enable Defender for Containers](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-enable)
- [View & remediate vulnerabilities (registry images)](https://learn.microsoft.com/en-us/azure/defender-for-cloud/view-and-remediate-vulnerability-registry-images)
- [Implement security recommendations](https://learn.microsoft.com/en-us/azure/defender-for-cloud/implement-security-recommendations)
- (Concept) Digest pinning best practices (search Azure container security guidance)

---
For troubleshooting, see the [Student FAQ](./FAQ.md). For support, contact your hackathon coach.
