# contracts/

## What's here now

- `vocabulary.yaml` — the machine-readable shared vocabulary (v0.4). Its
  owning spec is `specs/PROGRAM_SHARED_VOCABULARY_v0.4.md`. Consuming
  repositories vendor it unchanged and record its SHA-256; it is the
  comparison target for cross-repo conformance checks.

## Reserved: the shared schemas package

Reserved for the shared contracts package: `SemanticRecordSchema`,
`AnswerTraceSchema`, the future action record, and the canonicalization
implementation (JCS / RFC 8785) so hashing and signing are identical
everywhere.

**Authority today is hometown.** `SemanticRecordSchema` and
`AnswerTraceSchema` live in `hometown/src/core/` and are validated by
hometown's CI gate. Nothing here supersedes that.

**Trigger for extraction** (from the component gap assessment): the
earlier of

- sister-organization sharing beginning — external consumers must not
  vendor hometown's engine just to validate an envelope, or
- POC E (federation) development starting.

When triggered, the schemas move here, are published as a small
versioned package, and hometown consumes the package instead of owning
the files. Until then the schemas stay out of this directory on purpose:
extracting a contracts package before it has a second consumer buys nothing and
costs a release process.
