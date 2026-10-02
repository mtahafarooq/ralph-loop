# Requirements discovery guide

## Inspect before asking

Read relevant repository guidance and identify:

- current product behavior and terminology;
- affected users, surfaces, services, and data;
- established architecture and compatibility constraints;
- existing test, release, migration, and observability patterns.

Do not ask questions already answered by the repository.

## Discover the requirement

Ask focused questions in small batches. Cover only relevant categories:

1. **Problem:** What is wrong or missing today? What evidence supports it?
2. **Outcome:** What measurable or observable result defines success?
3. **Users:** Who performs the workflow, and who is affected?
4. **Scope:** What behavior is included? What is explicitly excluded?
5. **Workflow:** What are the main path, alternate paths, and failure paths?
6. **Rules:** What validation, authorization, state, or business rules apply?
7. **Data:** What is created, read, changed, retained, migrated, or deleted?
8. **Interfaces:** Which UI, API, CLI, event, or integration contracts change?
9. **Quality:** Which security, privacy, accessibility, reliability, performance, or scale constraints matter?
10. **Delivery:** Are rollout, compatibility, migration, feature flags, monitoring, support, or rollback required?
11. **Validation:** How can each outcome be proven with automated or manual checks?

## Classify information

Keep these categories distinct:

- **Confirmed:** directly stated or proven by repository evidence.
- **Constraint:** a mandatory boundary on the solution.
- **Assumption:** a temporary proposition requiring validation.
- **Open question:** unresolved information that may change scope or behavior.

Ask for clarification when an unresolved answer changes core behavior, data safety, permissions, compatibility, or acceptance criteria. Do not block drafting for low-impact details; mark them clearly.
