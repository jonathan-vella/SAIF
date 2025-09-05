# Coach Quality Red Flags
Companion to the student consolidated quality checklist. Use to quickly spot risk areas in submissions and intervene early.

## How To Use
Scan the relevant challenge section during midpoint and final review. If two or more red flags appear, coach the team to correct before moving on.

---
## Challenge 01
| Red Flag | Why It Matters | Coaching Action |
|----------|----------------|-----------------|
| Missing domains (one or more blank) | Incomplete baseline undermines later phases | Ask for rapid gap fill with minimally viable rows |
| Requirement phrased as product name only | Locks into solution prematurely | Rephrase to outcome, then map to options |
| Business Priority column generic ("Security") | No business linkage | Force explicit Compliance vs User Experience justification |
| No references | Reduces credibility & reuse | Direct to customer story + authoritative docs |

## Challenge 02
| Red Flag | Why It Matters | Coaching Action |
|----------|----------------|-----------------|
| Future Need == identical to Gap wording | No target clarity | Have them restate desired end state concretely |
| All controls immediate (no phasing) | No prioritization discipline | Introduce necessity to defer lower risk items |
| MFA lumped generically | Misses privileged vs standard nuance | Split privileged flows and justify stronger controls |

## Challenge 03
| Overly complex diagram (tool noise) | Obscures intent | Request simplified logical view |
| Missing monitoring/logging elements | Detection blind spots later | Prompt inclusion of observability components |
| Controls listed without Gap mapping | Weak justification | Require explicit "addresses Gap: X" tag |

## Challenge 04
| Deployment deviates silently from design | Traceability lost | Ask for deviation rationale section |
| Security rules undocumented | Hard to review risk profile | Require rule table with purpose |

## Challenge 05
| WAF added but no attack evidence | Unvalidated control | Request at least two blocked attack examples |
| Broad allow rules added | Weakens posture | Challenge necessity; narrow scope |

## Challenge 06
| DNS plan omits resolution consumers | Risk of name resolution failure | Ask for consumer mapping (service → record) |
| Steps unordered | Execution friction later | Have them number and reorder logically |

## Challenge 07
| Public endpoints still reachable | Objective not met | Immediate remediation guidance |
| No validation artifacts | Unproven state | Require test matrix or screenshots |

## Challenge 08
| All vulnerabilities treated equally | Inefficient remediation | Enforce prioritization criteria usage |
| Remediation changed app logic | Undermines training design | Roll back and constrain to hygiene changes |
| No before/after delta | Cannot show improvement | Ask for severity table comparison |

---
## Cross-Cutting Red Flags
| Red Flag | Impact | Coaching Action |
|----------|--------|-----------------|
| Vague verbs (improve, enhance) dominate | Low implementability | Convert to measurable outcome statements |
| Missing Gap → Action linkage | Weak traceability | Enforce explicit linkage notation |
| Unjustified deferrals | Hidden risk acceptance | Require deferral rationale column |
| Sensitive data in evidence | Potential disclosure | Instruct removal and sanitization |

---
_Last updated: 2025-09-05_
