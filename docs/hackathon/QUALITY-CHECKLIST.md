# Consolidated Quality Checklist

Central reference for student challenge quality expectations. Each challenge links here to avoid repetition. Use this as a pre‑submission self‑review.

## How To Use
1. Locate your current challenge.
2. Tick each item; if any unchecked, address before requesting review.
3. Attach listed Submission Artifacts (see challenge file) when done.

---
## Challenge 01 – Business Case & Requirements
- All four domains (Identity, Network, Database, Application) represented.
- Every row: Requirement (outcome), Current Gap, Future Need, Business Priority, Reference.
- No vague verbs ("improve", "enhance") without measurable framing.
- Business Priority explicitly states Compliance or User Experience.
- References are authoritative or from the customer story.

## Challenge 02 – Identity Remediation Plan
- Table includes clear control outcomes (not product names only).
- Gap → Future Need mapping explicit per row.
- Privileged access requirements separated from standard access.
- MFA / conditional policies justified via business priority.
- References cite Entra/Conditional Access documentation.

## Challenge 03 – Zero Trust Network Design
- Diagram shows segmentation, perimeter, identity-aware access, monitoring.
- Each control justification lists addressed Gap + Future Need.
- Hub/spoke (or chosen pattern) rationale stated.
- References include Zero Trust and CAF sources.

## Challenge 04 – Network Deployment
- Deployed topology matches Challenge 03 diagram (note any intentional deviations).
- Peering, routing, and security rules evidenced (screenshots/config extracts).
- Each control linked back to prior Gap.
- NSG / Firewall rules documented with purpose (least privilege rationale).

## Challenge 05 – WAF Implementation
- WAF model choice justified (why this deployment model).
- Policy/rule list ties each rule to an attack class or Gap.
- Attack evidence: Attempt → Expected → Observed (blocked) with log snippet.
- Optional JS challenge evidence (if pursued).

## Challenge 06 – Private Endpoint & DNS Planning
- All public endpoints enumerated (Web, API, SQL) with risk-oriented Gaps.
- Future Need states private-only access + DNS resolution strategy.
- Sequenced remediation steps (order makes sense; dependencies noted).
- DNS zone mapping (record types + consumers) documented.

## Challenge 07 – Private Connectivity Implementation
- Public access removed (validated externally or via failure evidence).
- Private Endpoints created for each service with correct DNS resolution.
- Validation steps reproducible (commands or screenshots).
- Gap → Action → Future Need mapping clear.

## Challenge 08 – Defender for Containers / Supply Chain
- Defender plans enabled (evidence captured).
- Baseline severity distribution + Top 5 vulnerability table.
- Prioritization rationale uses risk factors (exploitability, exposure, fix availability).
- Remediation scoped to hygiene (no business logic changes).
- Before/after delta + residual risk documented.
- (Stretch) Digest pinning or gate concept proposed.

---
## General Quality Patterns (All Challenges)
- Outcome phrasing ("MUST", target state) over tool configuration syntax.
- Traceability: every remediation/action ties to a documented Gap.
- References vendor-neutral where possible unless product feature specific.
- Evidence is legible: tables / screenshots labeled.
- Deferrals explicitly justified (why *not now*).

## Submission Pre‑Flight (All Challenges)
- [ ] File names and links correct.
- [ ] All tables render properly in Markdown.
- [ ] No TODO placeholders remain.
- [ ] Sensitive information (keys, secrets) excluded.

---
_Last updated: 2025-09-05_
