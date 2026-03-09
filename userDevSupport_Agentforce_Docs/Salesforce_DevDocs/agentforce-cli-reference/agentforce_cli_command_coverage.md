# Agentforce CLI Command Coverage (sf / sfdx)

## 1. Purpose
This document summarizes:
- Command list available for Agentforce development via Salesforce CLI
- What each command can do
- Practical scope that is possible from CLI

Use this as learning material for AI context and onboarding.

## 1.1 Operating Premise (Important)
- Always verify detailed and up-to-date behavior by running CLI help commands directly.
- Treat this document as a capability map, not as the final source of truth.
- For each command used in real work, confirm options and prerequisites with:
  - `sf <command> --help`
  - `sfdx <command> --help` (if compatibility behavior is relevant)
- If any discrepancy exists between this document and current help output, prioritize the help output.

## 2. Verification Context
- Date: 2026-03-07
- Repository: `kazu-hero/pfPhase2`
- Branch: `main`
- OS: Windows
- CLI version: `@salesforce/cli/2.105.6`
- Verified plugin: `agent 1.20.11`

## 3. Verification Method
The following help commands were executed and checked:
- `sf --version`
- `sfdx --version`
- `sf plugins --core`
- `sf agent --help`
- `sf agent create --help`
- `sf agent preview --help`
- `sf agent generate --help`
- `sf agent generate agent-spec --help`
- `sf agent generate test-spec --help`
- `sf agent generate template --help`
- `sf agent test --help`
- `sf agent test create --help`
- `sf agent test run --help`
- `sfdx agent --help`
- `sfdx agent generate --help`
- `sfdx agent test --help`

## 4. Command List and Capability Map

### 4.1 Top-level group
- `sf agent`
  - Purpose: Commands to work with agents.

### 4.2 Generate commands
1. `sf agent generate agent-spec`
- Generates an Agent spec YAML (`agentSpec.yaml` style).
- Uses org context and LLM to generate topics from role/company info.
- Supports iterative refinement via existing spec input.
- Output is used as input to `sf agent create`.

2. `sf agent generate test-spec`
- Generates Agent test spec YAML interactively.
- Can convert existing `AiEvaluationDefinition` metadata XML into YAML.
- Output is used as input to `sf agent test create`.

3. `sf agent generate template`
- Generates Bot template metadata from existing local metadata.
- Packaging-oriented flow for managed package distribution.
- Works with metadata types:
  - `Bot`
  - `BotVersion`
  - `GenAiPlanner`
  - Output `BotTemplate`

### 4.3 Create / Preview commands
1. `sf agent create`
- Creates an Agent in org from local Agent spec YAML.
- Can run with `--preview` to generate JSON preview without saving.
- Retrieves associated metadata into local DX project.

2. `sf agent preview`
- Opens interactive conversation preview with active Agent.
- CLI equivalent of Agent Builder conversation preview.
- Can save transcripts/API responses to output directory.
- Requires Connected App and OAuth setup before use.

### 4.4 Test commands
1. `sf agent test create`
- Creates Agent test in org from local test spec YAML.
- Generates/syncs metadata type `AiEvaluationDefinition` in DX project.
- Supports `--preview` and overwrite behavior.

2. `sf agent test run`
- Starts Agent test run.
- Supports wait mode and multiple result formats (`human`, `json`, `junit`, `tap`).
- Supports writing results to output directory.

3. `sf agent test list`
- Lists available Agent tests in org.

4. `sf agent test results`
- Gets results of completed Agent test run.

5. `sf agent test resume`
- Resumes previously started test job and fetches outcome.

## 5. sfdx Compatibility
- `sfdx agent --help` shows the same command family backed by `sf` command structure.
- Practical guidance:
  - Prefer `sf ...` syntax for new scripts and docs.
  - `sfdx ...` can still be used as compatibility entry point in current setup.

## 6. What Is Confirmed as CLI-possible
Confirmed by help-level inspection:
1. Generate agent specification files
2. Create agents in org from specs
3. Preview agent behavior interactively from terminal
4. Generate agent test specs
5. Create and run agent tests
6. Retrieve test results in machine-readable formats
7. Generate package-oriented agent templates from metadata

Confirmed by execution-level verification:
8. Bulk-retrieve agent-related metadata via `Agent` metadata key
   - Command example:
     - `sf project retrieve start --metadata Agent:UserDevSupportAgent --target-org pfPhase2Org`
   - Retrieved types in this project/org:
     - `Bot`
     - `BotVersion`
     - `GenAiPlannerBundle`
     - `GenAiPlugin` (topic plugin files)
   - Practical use:
     - Useful for syncing Agent Builder-side changes and plugin/planner bundle state in one command.

## 7. Known Constraints
1. Several commands are marked `beta` or `preview`.
2. `sf agent preview` requires additional Connected App/OAuth preparation.
3. Full lifecycle is often hybrid in practice (CLI + Agent Builder UI), especially for deeper configuration and tuning.
4. `GenAiPlanner` (singular type) may not be retrievable directly in current API/registry context; use `Agent:<Agent_API_Name>` retrieval to obtain `GenAiPlannerBundle` and related artifacts.

## 8. Suggested Minimal Workflow
1. `sf agent generate agent-spec ...`
2. `sf agent create --spec ...`
3. `sf agent preview --api-name ...`
4. `sf agent generate test-spec`
5. `sf agent test create --spec ...`
6. `sf agent test run --api-name ... --wait ...`
7. `sf agent test results` or `sf agent test resume`

## 9. Notes for AI Training
- This document is based on CLI help output, not full end-to-end execution of every command.
- Use this as capability map and command taxonomy.
- For detailed usage, always run the latest help command and re-validate assumptions.
- For production runbooks, add org-specific prerequisites (auth aliases, connected app policy, permission sets, CI variables).
