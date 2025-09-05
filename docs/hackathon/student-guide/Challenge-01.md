# Challenge 01: Mission Brief – Mapping the Security Landscape
# Timeline & Milestones
| Suggested Duration | Recommended Milestones |
|--------------------|------------------------|
| 1 hour             | Requirements captured, rubric understood |
## Objective

Understand the customer’s business context and concisely document the initial security requirements across identity, network, database, and application layers. Your output becomes the foundation for later technical decisions—focus on clarity, justification, and traceability.
## Scenario

You are a security consultant engaged by IFS to support the secure evolution of their AI‑powered application (SAIF). A baseline (intentionally vulnerable) environment exists. Your first mission is not to fix anything—but to map what matters: business drivers, security-relevant assets, and the initial requirement set that will guide subsequent hardening.

Keep the language business‑aware and implementation‑agnostic. Avoid jumping ahead to specific products or controls (e.g., “Use Service X”). State the need, not the solution.
## Instructions

1. **Review the Customer Story**  
   Read the business case at [IFS Customer Story](https://jonathan-vella.github.io/xlr8-e2eaisolutions/customer-story/). Extract:
   - Primary business goals (growth, trust, regulatory posture, customer experience)
   - Key stakeholders and their concerns
   - Operational or time constraints that influence prioritization

2. **Identify Key Requirements**  
   Capture concise, declarative requirements for:
   - **Identity** (authentication model, access boundary expectations)
   - **Network** (segmentation intent, exposure minimization, connectivity needs)
   - **Database** (confidentiality, access patterns, backup/restore expectations)
   - **Application** (security behaviors, resilience, compliance considerations)
   For each requirement, note:
   - **Current Gap** (what’s missing or weak now)
   - **Future Need** (target state description)
   - **Business Priority** (why it matters: compliance vs user experience)

3. **Document Your Findings**  
   Populate the table below. Add rows as required. Be specific—avoid vague terms like “improve” or “enhance” without measurable context.

## Requirements Table

| Area | Requirement | Current Gap | Future Need | Business Priority (Compliance/User Experience) | Reference |
|------|-------------|------------|-------------|-----------------------------------------------|-----------|
| Identity |  |  |  |  |  |
| Network |  |  |  |  |  |
| Database |  |  |  |  |  |
| Application |  |  |  |  |  |

<!-- Example (remove before submitting):
| Identity | All privileged admin actions MUST require MFA and role assignment review every 30 days | Privileged roles assigned permanently; some accounts lack MFA | Time-bound (PIM-style) elevation with enforced MFA challenge for all privileged actions | Compliance (reduces audit exposure) | IFS Story, CAF Governance, Entra Conditional Access Docs |
-->
## Success Criteria

- Clear, structured table covering identity, network, database, and application domains.
- Each requirement links a current gap to a defined future need.
- Compliance or user experience priority is explicitly stated (not implied).
- References justify why the requirement exists (business case or authoritative guidance).
- Language is outcome‑focused and implementation‑neutral.
## Scoring Rubric

## Quality Checklist
- Each requirement row has: Requirement, Current Gap, Future Need, Business Priority, Reference.
- Wording is outcome-based (no hard product lock unless justified).
- Business Priority clearly states Compliance or User Experience.
- References map to business story or authoritative docs.
- No vague verbs without measurable target.

See consolidated checklist: [QUALITY-CHECKLIST](../QUALITY-CHECKLIST.md#challenge-01--business-case--requirements)

### Submission Artifacts
- Requirements table (Markdown)
- Any references list (inline or separate)
- (Optional) Brief rationale for top 3 priorities

| Criteria                        | Excellent (5) | Good (3) | Needs Improvement (1) |
|---------------------------------|---------------|----------|-----------------------|
| Completeness of Requirements    | All domains fully covered; each entry has gap & future state | Most domains covered; minor omissions | Significant omissions or vague entries |
| Alignment to Business Case      | Every requirement tied to explicit business driver/reference | Some ties made but inconsistent | Little or no traceability provided |
| Focus on Compliance & UX        | Priority and rationale clearly articulated | Priority noted but rationale thin | Missing or unclear priorities |
| Use of References               | Multiple authoritative, relevant references | Limited references | None or irrelevant |
| Table Format & Clarity          | Consistent, readable, unambiguous phrasing | Minor formatting or clarity issues | Disorganized or hard to interpret |
**Tip:**  
State requirements in a testable, outcome form. Example: “All privileged administrative access MUST require MFA and role assignment review every 30 days” (clear) vs “Harden admin access” (vague). Capture the *why*—it will accelerate later design decisions.
 Challenge 01: Mission Brief – Mapping the Security Landscape
# Timeline & Milestones
| Suggested Duration | Recommended Milestones |
|--------------------|-----------------------|
| 1 hour             | Requirements defined, rubric reviewed |

## Objective

Understand the customer’s business case and document key requirements related to identity, network, database, and application security.

## Scenario

You are a security consultant for IFS, tasked with modernizing their AI-powered application (SAIF). Your first mission is to analyze the business context and identify critical requirements that will shape your security strategy.

## Instructions

1. **Review the Customer Story**
   - Read the business case at [IFS Customer Story](https://jonathan-vella.github.io/xlr8-e2eaisolutions/customer-story/).
   - Identify the main business goals, stakeholders, and operational constraints.

2. **Identify Key Requirements**
   - List requirements for:
     - **Identity** (e.g., user authentication, access control)
     - **Network** (e.g., connectivity, segmentation, perimeter security)
     - **Database** (e.g., data protection, access, backup)
     - **Application** (e.g., functionality, security, compliance)
   - For each area, document:
     - **Current Gaps**
     - **Future Needs**
     - **Business Priorities** (focus on compliance and user experience)

3. **Document Your Findings**
   - Use the table format below to organize requirements. Add rows as needed.

---

## Requirements Table

| Area        | Requirement                | Current Gap | Future Need | Business Priority (Compliance/User Experience) | Reference |
|-------------|----------------------------|-------------|-------------|-----------------------------------------------|-----------|
| Identity    |                            |             |             |                                               |           |
| Network     |                            |             |             |                                               |           |
| Database    |                            |             |             |                                               |           |
| Application |                            |             |             |                                               |           |

---

## Success Criteria

- A clear, well-structured table outlining key requirements for identity, network, database, and application.
- Requirements address both current gaps and future needs.
- Compliance and user experience priorities are highlighted.
- All requirements are mapped to the business case and justified with references.

---

## Scoring Rubric

| Criteria                        | Excellent (5) | Good (3) | Needs Improvement (1) |
|---------------------------------|---------------|----------|-----------------------|
| Completeness of Requirements    | All areas covered with detailed gaps and needs | Most areas covered, some details missing | Major areas missing or vague |
| Alignment to Business Case      | Requirements clearly mapped and justified | Some mapping, limited justification | Little/no mapping to business case |
| Focus on Compliance & UX        | Priorities clearly highlighted and explained | Mentioned but not explained | Not addressed |
| Use of References               | Multiple relevant references included | Some references | No references |
| Table Format & Clarity          | Table is clear, organized, easy to read | Table present but could be improved | Table missing or unclear |

---

## References

- [IFS Customer Story](https://jonathan-vella.github.io/xlr8-e2eaisolutions/customer-story/)
- [Functional Requirements Example](https://jonathan-vella.github.io/xlr8-e2eaisolutions/docs/02-agent/ifs-agent-step2-functional-requirements/)
- [Microsoft Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)

---

**Tip:**
Focus on understanding the “why” behind each requirement. This will help you design effective security solutions in later challenges.
