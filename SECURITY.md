# Security and Privacy Boundary

AeroShift is a standalone personal project. It is not affiliated with, sponsored by, endorsed by, or developed for FedEx Corporation, any subsidiary, or any employer.

## Safe development rules

- Use synthetic or personally owned roster data in source files, screenshots, tests, issues, and pull requests.
- Never commit employer-provided schedules, confidential documents, credentials, tokens, internal URLs, proprietary code, or operational data.
- Keep the baseline app offline-first. Do not add network, analytics, account, or employer-service integrations without an explicit design and privacy review.
- Treat imported roster text as sensitive personal data even when it is locally stored.

## Accidental exposure

If sensitive or employer-related material is committed accidentally, stop sharing the repository, remove the material from the working tree, and rotate any exposed credential. Do not paste the sensitive content into a public issue or pull request; use a private channel to coordinate cleanup.
