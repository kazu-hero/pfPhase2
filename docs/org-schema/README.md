# Org Schema Snapshot

This folder stores reusable snapshots of Salesforce object schema metadata.

## Purpose

- Keep a current snapshot in `latest/` for daily reference.
- Keep point-in-time snapshots in `history/<timestamp>/` after each update.
- Re-run the same process any time the org metadata changes.

## Output structure

For each org alias, files are generated under:

- `docs/org-schema/<OrgAlias>/latest/`
- `docs/org-schema/<OrgAlias>/history/<yyyyMMdd-HHmmss>/`

Generated files:

- `entity-definitions.csv`: all entity definitions (object-level overview)
- `custom-objects.csv`: custom objects and custom metadata objects (`__c`, `__mdt`)
- `custom-field-summary.csv`: field summary for custom objects from `describe`
- `describes/custom/<ObjectApiName>.json`: full object describe payload
- `manifest.json`: generation metadata and file list

## How to run

Run from workspace root:

```powershell
npm run schema:export
```

Optional org alias override:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\schema\export-org-schema.ps1 -OrgAlias "pfPhase2Org"
```

## Notes

- Requires Salesforce CLI (`sf`) and an authenticated org.
- Default alias is `pfPhase2Org`.
- The script updates `latest/` and appends one snapshot to `history/` every run.
