# Phase 3.1-2 Knowledge Integration Plan

## Purpose
Define an implementation-ready plan to enable Knowledge integration for UserDevSupportAgent and improve guidance quality for non-code development support.

## Scope
- Target agent metadata:
  - `force-app/main/default/bots/UserDevSupportAgent/v1.botVersion-meta.xml`
  - `force-app/main/default/genAiPlugins/p_16jdL000002lnH3_*.genAiPlugin-meta.xml`
- Target knowledge content:
  - Phase 3 prioritized 10 guides from `08_guide_structure.md`

## Phase 3 Priority Guides (10)
1. G-101: Custom object creation
2. G-201: Custom field creation
3. G-202: Picklist field creation
4. G-203: Formula field creation
5. G-301: Page layout editing
6. G-302: Record type setup
7. G-401: Lookup relationship setup
8. G-402: Master-detail relationship setup
9. G-501: Basic screen flow creation
10. G-601: Validation rule setup

## Topic to Knowledge Mapping
- Topic 3 (`Non Code Development Guidance`): G-301, G-302, G-501
- Topic 4 (`Custom Object Setup`): G-101, G-201, G-202, G-203, G-401, G-402
- Topic 5 (`Validation Rule Assistance`): G-601

## Implementation Tasks
### T1. Knowledge content package preparation
- Create a structured knowledge source set for the 10 guides.
- Normalize guide format (title, prerequisites, steps, completion checks).

### T2. Bot knowledge switches proposal
- Prepare metadata diff proposal for:
  - `knowledgeActionEnabled`
  - `knowledgeFallbackEnabled`
- Keep changes minimal and reversible.

### T3. Topic-level instruction update proposal
- Add explicit instruction to use knowledge source before generic explanation.
- Preserve current Japanese-default policy.

### T4. Integration test design
- Define test matrix by Topic x Guide x Expected behavior.
- Include negative cases (missing guide, out-of-scope query).

## Acceptance Criteria
- Knowledge usage path is defined for Topic 3/4/5.
- Priority 10 guides are mapped and traceable.
- Bot setting change proposal is documented.
- Integration test cases are documented and executable.

## Risks and Controls
- Risk: Knowledge source not configured in org.
  - Control: Keep fallback behavior explicit; avoid hard dependency in first rollout.
- Risk: Topic responses become inconsistent.
  - Control: Add topic-level instruction to prefer mapped guides.
- Risk: Scope drift to pro-code answers.
  - Control: Keep non-code-first constraints from `02_solution_definition.md`.

## Next Step
Prepare concrete metadata diff proposal for `v1.botVersion-meta.xml` and `lnH3` topic instructions, then present for approval before applying file changes.
