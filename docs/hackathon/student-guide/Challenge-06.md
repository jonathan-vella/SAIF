---
version: 1.0.0
last_updated: 2025-07-17
guide_type: student
challenge: 06
title: Planning Private Endpoints and Private DNS Zone Implementation
---

# Challenge 06: Planning Private Endpoints and Private DNS Zone Implementation
# Timeline & Milestones
| Suggested Duration | Recommended Milestones |
|--------------------|-----------------------|
| 1 hour             | Remediation plan and DNS strategy documented |

## Objective
Develop a remediation plan to remove all public endpoints (Web, API, SQL) from SAIF and design an implementation strategy for Private DNS Zones in Azure.

## Scenario

Your SAIF environment currently exposes public endpoints for the web front end, API, and SQL database. To improve security and compliance, you must plan how to eliminate these public endpoints and transition to private connectivity using Azure Private DNS Zones.

## Instructions

1. **Assess Current Exposure**
   - Identify all public endpoints in your SAIF deployment (Web, API, SQL).
   - Document risks (Current Gaps) and business impacts of public exposure.

2. **Develop a Remediation Plan**
   - Outline steps to remove public access for each endpoint (Gap → Future Need mapping).
   - Specify which Azure services and features (e.g., Private Endpoints, Private Link, NSGs) will be used.
   - Address migration, downtime, and user access considerations.

### Suggested Table Structure

| Endpoint | Current Gap | Future Need | Business Priority (Compliance/User Experience) | Reference |
|----------|-------------|-------------|-----------------------------------------------|-----------|
| Web Front End | Public HTTPS exposure; no network boundary | Accessible only via private endpoint + internal DNS; no direct public access | Compliance | Azure Private Endpoint Docs |
| API |  |  |  |  |
| SQL Database |  |  |  |  |

<!-- Example row (remove before submitting):
| Web Front End | Public endpoint accessible from any IP | Private Endpoint + DNS zone resolution only from hub VNet | Compliance | Azure Private Endpoint; Private DNS Zones |
-->

3. **Design Private DNS Zone Implementation**
   - Plan the creation and configuration of Azure Private DNS Zones for your environment.
   - Map out how private DNS will resolve internal service names and support secure connectivity.
   - Document dependencies and integration points.

4. **Document Your Plan**
   - Submit a written remediation plan and Private DNS Zone implementation strategy.
   - Include diagrams, tables, or checklists as needed for clarity.
   - Reference Azure documentation and best practices.

## Success Criteria

- All public endpoints identified and risks documented.
- Remediation plan clearly outlines steps and Azure features for removing public access.
- Private DNS Zone implementation strategy is detailed and actionable.
- Documentation includes diagrams/tables and references.

## Scoring Rubric

## Quality Checklist
- All public endpoints enumerated with explicit Current Gap wording.
- Future Need phrased as a target state (not tool-only statement).
- Remediation steps sequenced logically (prerequisites clear).
- DNS strategy covers name resolution + lifecycle (creation, linking, updates).
- Business Priority specified for each major remediation step.

See consolidated checklist: [QUALITY-CHECKLIST](../QUALITY-CHECKLIST.md#challenge-06--private-endpoint--dns-planning)

### Submission Artifacts
- Endpoint exposure table
- Remediation plan steps (ordered)
- DNS design notes / mapping

| Criteria                        | Excellent (5) | Good (3) | Needs Improvement (1) |
|---------------------------------|---------------|----------|-----------------------|
| Endpoint Identification         | All endpoints identified, risks documented | Most endpoints identified | Few/no endpoints identified |
| Remediation Plan                | Clear, actionable, covers all endpoints | Partial plan, some gaps | Vague or missing plan |
| Private DNS Zone Strategy       | Detailed, covers integration and dependencies | Partial strategy | Missing or unclear strategy |
| Documentation                   | Diagrams/tables, clear references | Partial documentation | No documentation |

## References

- [Azure Private Endpoint Documentation](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [Azure Private DNS Zone Documentation](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview)

---

**Tip:**
Focus on actionable planning and clear documentation to support a secure transition to private connectivity.
