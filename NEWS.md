# heuristR 0.0.0.9000

- Added session, metadata, record, and safe write helpers for Heurist.
- Added rollback helpers for reversible scripted changes.
- Added permanent tests for unit and live integration workflows.
- Added package documentation, a public README, and an archaeology-focused vignette.
- Added guarded schema-creation helpers for record types, detail types,
  vocabularies, terms, vocabulary groups, and record-structure attachment.
- Added a low-level `heurist_raw_entity_edit()` POST helper while keeping the
  higher-level schema helpers create-only by default to reduce accidental
  destructive updates.
