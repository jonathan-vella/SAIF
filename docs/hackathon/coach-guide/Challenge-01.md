# Coach Guide: Challenge 01 – Mission Brief

## Purpose

Enable consistent coaching for Challenge 01 by reinforcing disciplined requirement capture (Current Gap → Future Need → Business Priority) without premature solutioning. Coaches should steer teams toward clarity, traceability, and justified scope—not architecture decisions.

---

## Learning Outcomes

- Students interpret the business scenario and translate it into initial security requirements.
- Students clearly differentiate Current Gap vs Future Need for each requirement.
- Students articulate Business Priority (compliance or user experience) explicitly.
- Students produce a structured table with authoritative references.

---

## Facilitation Tips

- Insist they extract business goals first; if goals aren’t written down, pause work.
- Watch for solution bias (e.g., “Use Conditional Access”)—redirect to outcome phrasing (“Enforce adaptive access policy for privileged actions”).
- Check column completeness early (some teams skip Future Need or Business Priority—intervene quickly).
- Encourage referencing authoritative sources (CAF, Zero Trust, product docs) not generic blogs.
- Reinforce measurable language (avoid “improve”, prefer “MUST”, “SHALL”, or outcome with cadence/threshold).
- Limit time spent polishing wording—breadth + clarity over perfection.

---

## Common Pitfalls

- Missing one or more domains entirely.
- Writing future state as a product name (solution lock-in).
- Vague verbs (“improve”, “strengthen”, “harden”) without measurable target.
- No reference cited (reduces credibility & reusability downstream).
- Business Priority column filled with “Security” (push them to choose compliance vs user experience driver).

---

## Coaching Prompts

- “Which business goal does this requirement trace to?”
- “What’s the explicit Current Gap evidence?”
- “Is the Future Need written in an outcome (not tool) form?”
- “Why is this Compliance vs User Experience—justify the choice.”
- “What authoritative reference can you attach?”
- “Could someone implement later without asking you clarifying questions?”

---

## Assessment Guidance

Rubric anchors (Excellent band) should require:
- All four domains present (identity, network, database, application)
- Each row has: Requirement (outcome), Current Gap, Future Need, Business Priority, Reference
- No vague verbs without quantifier or cadence
- Each requirement defensible via cited source or business goal
- Table formatting consistent (readability = minimal friction)

---

## References

- [IFS Customer Story](https://jonathan-vella.github.io/xlr8-e2eaisolutions/customer-story/)
- [Functional Requirements Example](https://jonathan-vella.github.io/xlr8-e2eaisolutions/docs/02-agent/ifs-agent-step2-functional-requirements/)
- [Microsoft Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)

---

**Coach Tip:**
If a team stalls: have them draft one exemplar row (identity) to “set the pattern” then parallelize remaining rows across members. Quality accelerates once pattern clarity is achieved.
