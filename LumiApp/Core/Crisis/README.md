# Crisis pattern list

`Lumi_Crisis_Protocol.docx` §5 states the trigger pattern list is approved
by the psychologist separately and must not be published in open product
documents. Treat it the same way in code: it must never be committed to
this repository in plaintext.

To develop/test crisis detection locally:

1. Get the real pattern list from the psychologist/product owner through a
   secure, non-git channel.
2. Save it as `LumiApp/Resources/CrisisPatterns.json` — a flat JSON array
   of strings, e.g. `["example phrase one", "example phrase two"]`.
3. This path is already git-ignored (see root `.gitignore`) and picked up
   automatically as a bundle resource on the next `xcodegen generate`.

`CrisisPatterns.example.json` next to this file is a fake, safe-to-commit
sample showing the expected format — it is excluded from the build target
(see `project.yml`) and is documentation only, not something the app reads.

Before any release: re-verify this list is current, and re-verify the
helpline numbers in `CrisisSupportView.swift` (§5 of the protocol doc —
stale hotline numbers are called out as the most common failure mode in
this category of app).
