Implement this AI-processing flow in the existing app, preserving working features.

Keep captures local-first: photos, text/audio captions, existing Whisper.cpp transcripts, and guidance/templates. Preserve originals and explicit caption-to-photo links.

On “Process,” submit a versioned project to an authenticated backend. Use resumable, idempotent jobs with progress, cancellation, retries, and change-based caching. Derive requirements from templates; parse digital text directly and analyze related photos with captions/transcripts. Extract schema-validated records with source references. Never invent facts; flag missing values, conflicts, and uncertain item grouping for review. Generate template-preserving Excel, Word, and text from reusable approved records.

Provide managed AI by default and optional user-supplied API keys through configurable provider adapters. Store credentials encrypted server-side; exclude secrets from app bundles and logs. Use inexpensive extraction with budget-approved escalation; never silently switch providers or billing accounts.

Add spending limits, usage/cost tracking, private storage, deletion controls, tests, and setup documentation. Treat attached content as untrusted.