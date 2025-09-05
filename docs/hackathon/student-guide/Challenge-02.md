# Challenge 02: Guardians of Access – Designing the Identity Fortress
# Timeline & Milestones
| Suggested Duration | Recommended Milestones |
|--------------------|-----------------------|
| 1.5 hours          | Identity gaps identified, plan drafted |

## Objective

Develop a high-level remediation plan to address identity security gaps for the IFS business case.

## Scenario

You are tasked with strengthening identity security for SAIF. This is a design challenge—focus on planning, not building.

## Instructions

1. **Review the Business Case**
   - Reference [IFS Customer Story](https://jonathan-vella.github.io/xlr8-e2eaisolutions/customer-story/).

2. **Identify Critical Identity Security Areas**
   - Consider the following aspects as you build your plan:
     - What policies and controls can you implement to ensure only the right users, under the right conditions, can access cloud resources?
     - What safeguards should be in place for privileged and emergency access?
     - How can applications and workloads securely authenticate to Azure services?
     - What options exist for integrating cloud database authentication with enterprise identity?

3. **Document Your Remediation Plan**
    - Use a table to outline each area you identify with consistent terminology:
       - Description (concise requirement / control outcome)
       - Current Gap (what’s missing now)
       - Future Need (target state / control objective)
       - Business Priority (Compliance/User Experience)
       - Reference (authoritative source)

### Suggested Table Structure

| Area | Description | Current Gap | Future Need | Business Priority (Compliance/User Experience) | Reference |
|------|-------------|-------------|-------------|-----------------------------------------------|-----------|
|      |             |             |             |                                               |           |

<!-- Example row (remove before submitting):
| Privileged Access | Enforce MFA + time-bound elevation for all privileged roles | Some admin accounts lack MFA; permanent role assignments | All privileged actions require MFA; roles limited to just-in-time 1h elevation | Compliance | IFS Story; Entra Conditional Access Overview |
-->

## Success Criteria

- A clear, actionable remediation plan covering all critical identity security areas.
- Plan addresses both current gaps and future needs.
- Compliance and user experience are considered.
- References to best practices or documentation included.

## Scoring Rubric

## Quality Checklist
- Each row includes: Description, Current Gap, Future Need, Business Priority, Reference.
- Requirements are outcome-based (no premature product/config syntax).
- Business Priority states Compliance or User Experience explicitly.
- References are authoritative (docs, frameworks) not generic blogs.
- No vague verbs ("improve", "enhance") without measurable outcome.

See consolidated checklist: [QUALITY-CHECKLIST](../QUALITY-CHECKLIST.md#challenge-02--identity-remediation-plan)

### Submission Artifacts
- Identity remediation table
- Prioritized list (top 3–5 items with rationale)
- References list

| Criteria                        | Excellent (5) | Good (3) | Needs Improvement (1) |
|---------------------------------|---------------|----------|-----------------------|
| Coverage of Critical Areas      | All aspects covered in detail | Most aspects covered, some details missing | Major aspects missing or vague |
| Actionability of Plan           | Solutions are specific and actionable | Solutions are somewhat actionable | Solutions are vague or generic |
| Focus on Compliance & UX        | Priorities clearly highlighted and explained | Mentioned but not explained | Not addressed |
| Use of References               | Multiple relevant references included | Some references | No references |
| Table Format & Clarity          | Table is clear, organized, easy to read | Table present but could be improved | Table missing or unclear |

## References

- [IFS Customer Story](https://jonathan-vella.github.io/xlr8-e2eaisolutions/customer-story/)
- [Conditional Access Overview](https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview)
- [Microsoft Entra ID Documentation](https://learn.microsoft.com/en-us/azure/active-directory/)
- [Workload Identity Federation](https://learn.microsoft.com/en-us/azure/active-directory/workload-identity-federation/)
- [Azure SQL Authentication](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-azure-ad/)

---

**Tip:**  
Focus on “why” each solution is needed and how it supports business priorities.
