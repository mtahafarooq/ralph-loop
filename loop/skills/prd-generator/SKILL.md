---
name: prd-generator
description: Create or refine a human-readable product requirements document from an idea, feature request, problem statement, or rough specification. Use when asked to create a PRD, write requirements, plan a feature, define scope and acceptance criteria, or improve an existing PRD; do not use merely to implement approved requirements or convert them to Ralph JSON.
---

# PRD Generator

Create a decision-ready PRD without inventing requirements.

## Workflow

1. Inspect relevant repository documentation, architecture, manifests, and existing behavior before asking questions.
2. Read [the discovery guide](references/discovery-guide.md), then ask only the smallest useful batch of unanswered questions.
3. Separate confirmed requirements, explicit constraints, assumptions, and open questions.
4. Draft the PRD using [the template](assets/prd-template.md). Default to `loop/prd.md` unless another path is requested.
5. Review the draft with [the quality checklist](references/quality-checklist.md).
6. Resolve material ambiguity before presenting the PRD as approved. Clearly retain non-blocking open questions.
7. Never overwrite an existing PRD without confirmation. Propose a revision or patch when one already exists.
8. Stop after the human-readable PRD. Recommend `prd-to-json` only after the PRD is approved.

## Rules

- Describe outcomes and externally observable behavior. Prescribe implementation only when it is a real constraint.
- Make every acceptance criterion independently verifiable.
- Include explicit non-goals to control scope.
- Give requirements or user stories stable IDs that can survive later edits.
- Include security, privacy, accessibility, performance, compatibility, migration, rollout, and observability only when relevant; explicitly mark evaluated categories that need no special requirement.
- Do not silently treat an assumption as a confirmed requirement.
