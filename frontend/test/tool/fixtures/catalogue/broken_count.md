# Fixture — Template Catalogue

**3 distinct templates · 2 categories · 1 supergroups · Version 0.1.0**

## Shared archetype packs

**LOG — Activity / event log**

Fields: activity_type, start_time, end_time, participants_or_operators, observations, outcome.

**OBS — Observation / evidence capture**

Fields: observation_subject, observed_at, factual_description, media_refs, capture_context, verification_notes.

**TRANS — Transaction / repeated line items**

Fields: transaction_reference, transaction_date, parties, line_items, quantities, unit_or_currency, totals, source_documents.

# 01 · Fixture foundations

## UNI — Universal capture and records (2 templates)

Shared category context: organization_ref, project_ref.

### UNI-001 — General observation

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Specific starter fields:** observation_category, observed_details, approval_timestamp.

**Capture:** Photos; optional GPS and time.

**AI assistance:** Propose captions.

**Potential outputs:** Observation record.

**Review:** Keep observed and inferred apart.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

### UNI-002 — Shift log

**Type:** Activity / event log · **Shared pack:** LOG.

**Specific starter fields:** shift_name, head_count, fuel_cost.

**Capture:** Manual entry; time capture.

**AI assistance:** Order events.

**Potential outputs:** Activity log.

**Review:** Preserve corrections.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

## FIN — Finance accounting and expenses (2 templates)

Shared category context: accounting_period, currency_code.

### FIN-001 — Invoice OCR intake

**Type:** Transaction / repeated line items · **Shared pack:** TRANS. **Detailed starter schema included.**

**Specific starter fields:** invoice_number, supplier_name, invoice_date, weights_and_dimensions.

**Capture:** Invoice photos; manual entry.

**AI assistance:** Extract line items.

**Potential outputs:** Transaction register.

**Review:** Reconcile totals.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.
