# contracts/ (reserved — not yet populated)

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
the files. Until then this directory stays empty on purpose: extracting
a contracts package before it has a second consumer buys nothing and
costs a release process.
