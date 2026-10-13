# Tapture — Simple shipped template catalogue

**194 distinct templates · 72 categories · 17 supergroups · Version 2.0.0**

Each template captures one clear use in 5–8 optional atomic fields. Copy a starter and customize or extend it for specialist needs. Closely related organizational and workflow variants are omitted.

Record administration, location context, raw evidence and review history remain record data, not dozens of inherited template columns. Existing copied templates and captured versions are unchanged. Stable keys and codes are retained for surviving starters.

## Coverage

| Group | Categories | Templates |
|---|---:|---:|
| 01 · Cross-sector foundations | 4 | 11 |
| 02 · Business and governance | 4 | 11 |
| 03 · Collaboration and delivery | 4 | 11 |
| 04 · Health and life sciences | 5 | 16 |
| 05 · Education research and care | 4 | 11 |
| 06 · Buildings land and infrastructure | 4 | 12 |
| 07 · Agriculture and natural resources | 4 | 14 |
| 08 · Production and industry | 4 | 12 |
| 09 · Energy utilities and environment | 4 | 10 |
| 10 · Transport and supply chains | 5 | 12 |
| 11 · Digital systems and communications | 4 | 11 |
| 12 · Finance public administration and law | 4 | 12 |
| 13 · Risk resilience and sustainability | 4 | 10 |
| 14 · Social impact culture and information | 4 | 10 |
| 15 · Commerce hospitality and recreation | 4 | 11 |
| 16 · Professional specialist and personal services | 5 | 9 |
| 17 · Specialist and emerging domains | 5 | 11 |

## Shared archetype packs

These define reusable field types and record-type guidance. Simple starters select only their explicit fields; they do not inherit whole packs.

**AGREEMENT — Agreement / approval**

Fields: parties, purpose, terms, effective_date, expiry_date, approval_evidence.

**ASSESS — Assessment / analysis**

Fields: assessment_objective, criteria_reference, evidence_items, findings, assumptions, review_conclusion.

**ASSET — Register / master data**

Fields: item_identifier, item_name, category, manufacturer, model_number, serial_number, condition, custodian.

**CASE — Case-management workflow**

Fields: case_type, reported_details, source_reference, assigned_handler, case_stage, followup_actions, closure_basis.

**CHECK — Checklist / verification**

Fields: checklist_version, check_items, observed_results, exceptions, corrective_actions, reviewer.

**COMM — Communication draft**

Fields: audience, purpose, verified_facts, message_body, attachments, approved_sender.

**DOC — Generated document**

Fields: document_purpose, audience, required_sections, source_records, format_constraints, approved_version.

**INCIDENT — Incident workflow**

Fields: event_time, event_location, factual_description, immediate_action, affected_items, assigned_reviewer.

**INSPECT — Inspection / field form**

Fields: inspection_scope, criteria_reference, inspection_items, observed_condition, defects, recommended_actions.

**LEARN — Learning / competency record**

Fields: learning_objective, course_or_standard_ref, participant_refs, completion_evidence, assessment_result, assessor.

**LOG — Activity / event log**

Fields: activity_type, start_time, end_time, participants_or_operators, observations, outcome.

**MAINT — Maintenance workflow**

Fields: asset_ref, reported_problem, approved_work_scope, work_performed, parts_used, verification_results, next_due.

**MEASURE — Measurement / calculation**

Fields: measurement_type, value, unit, measurement_time, method_reference, instrument_ref, uncertainty_or_quality.

**MEET — Meeting / collaboration**

Fields: meeting_title, scheduled_time, attendees, agenda, discussion_notes, decisions, actions.

**OBS — Observation / evidence capture**

Fields: observation_subject, observed_at, factual_description, media_refs, capture_context, verification_notes.

**PLAN — Plan / schedule**

Fields: planning_objective, scope, activities, responsible_roles, dates, dependencies, resources, success_measures.

**PROFILE — Profile / intake**

Fields: display_name, entity_type, contact_channels, service_context, source_documents, permission_scope.

**PROPOSAL — Proposal-generation workflow**

Fields: opportunity_requirements, applicant_profile, project_objectives, methodology, workplan, budget, supporting_evidence, required_annexes.

**REG — Register / master data**

Fields: entry_identifier, record_subject, category, effective_date, source_reference, responsible_role, review_due.

**REPORT — Generated report**

Fields: reporting_scope, reporting_period, source_records, verified_findings, metrics, limitations, recommendations.

**REQUEST — Request / approval workflow**

Fields: request_purpose, requested_items_or_actions, justification, required_by, supporting_evidence, approver, decision.

**SAMPLE — Sample / chain-of-custody**

Fields: sample_identifier, sample_type, collection_time, collection_location, collection_method, requested_tests, custody_events.

**SURVEY — Survey / questionnaire**

Fields: survey_version, respondent_or_sample_code, consent_scope, questions_and_responses, sampling_context, interviewer_notes.

**TRACK — Tracker / follow-up**

Fields: tracked_item, current_stage, responsible_owner, target_date, latest_update, supporting_evidence, completion_criteria.

**TRANS — Transaction / repeated line items**

Fields: transaction_reference, transaction_date, parties, line_items, quantities, unit_or_currency, totals, source_documents.

**VISIT — Visit / field workflow**

Fields: visit_purpose, visited_site_or_party, visit_time, observations, discussion_notes, agreed_actions.

# 01 · Cross-sector foundations

## UNI — Universal capture and records (3 templates)

Shared category context: organization_ref, project_ref, subject_ref.

### UNI-001 — General observation

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Stable key:** uni_general_observation.

**Fields only:** observation_subject, observed_at, factual_description, observation_category, operator_note.

**Identity fields:** observation_subject, observed_at.

**Capture:** Photos; explicit audio captions; video; optional GPS and time.

**AI assistance:** OCR or transcribe visible evidence; propose tags and captions; retain source links.

**Potential outputs:** Observation record; photo sheet; annotated evidence bundle.

**Review:** Observed, reported and inferred details must remain distinguishable.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

### UNI-006 — Document record

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** uni_document_intake_and_indexing.

**Fields only:** entry_identifier, record_subject, document_type, document_date, source_reference.

**Identity fields:** entry_identifier.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

### UNI-007 — Contact record

**Type:** Profile / intake · **Shared pack:** PROFILE.

**Stable key:** uni_business_card_capture.

**Fields only:** contact_name, organization_name, phone_primary, email_address, operator_note.

**Identity fields:** contact_name.

**Capture:** Manual entry; approved documents; contact imports.

**AI assistance:** Extract supplied profile data; flag conflicts; reuse only approved facts.

**Potential outputs:** Profile card; directory entry; intake summary.

**Review:** Collect only necessary personal data; obtain required permissions.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

## AST — Assets and equipment (3 templates)

Shared category context: organization_ref, site_ref, asset_ref.

### AST-001 — Asset inventory

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** ast_equipment_master_inventory.

**Fields only:** item_identifier, item_name, manufacturer_name, model_number, serial_number, condition_grade, custodian_name.

**Identity fields:** item_identifier, serial_number.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

### AST-004 — Equipment condition check

**Type:** Assessment / analysis · **Shared pack:** ASSESS.

**Stable key:** ast_asset_condition_assessment.

**Fields only:** asset_ref, assessment_date, condition_grade, visible_defects, serviceability, review_conclusion.

**Identity fields:** asset_ref.

**Capture:** Documents; observations; photos; measurements.

**AI assistance:** Extract evidence; organize comparisons; calculate only with declared methods; propose review notes.

**Potential outputs:** Assessment worksheet; findings report; evidence appendix.

**Review:** Reviewer verifies evidence, assumptions and conclusions.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

### AST-007 — Maintenance record

**Type:** Maintenance workflow · **Shared pack:** MAINT.

**Stable key:** ast_corrective_maintenance_work_order.

**Fields only:** asset_ref, reported_date, reported_problem, work_performed, parts_used, verification_results, work_completed_date, technician_name.

**Identity fields:** asset_ref.

**Capture:** Asset scan; photos; manuals; technician notes.

**AI assistance:** Read identifiers and manuals; structure the service report; suggest follow-up for review.

**Potential outputs:** Work order; service history; parts usage; maintenance report.

**Review:** Qualified technician approves work and return to service.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

## INV — Inventory and warehousing (3 templates)

Shared category context: organization_ref, warehouse_ref, item_ref.

### INV-001 — Stock item

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** inv_stock_item_master.

**Fields only:** stock_code, item_name, unit_of_measure, quantity_counted, reorder_level, warehouse_ref.

**Identity fields:** stock_code.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

### INV-002 — Stock receipt

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** inv_goods_received_note.

**Fields only:** item_ref, transaction_date, counterparty_name, supplier_delivery_ref, received_quantity, received_quantity_unit, accepted_quantity, accepted_quantity_unit.

**Identity fields:** item_ref.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

### INV-005 — Stock count

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** inv_cycle_count_sheet.

**Fields only:** item_ref, check_date, book_quantity, book_quantity_unit, counted_quantity, counted_quantity_unit, variance_reason.

**Identity fields:** item_ref.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

## PRC — Procurement and suppliers (2 templates)

Shared category context: organization_ref, procurement_ref, supplier_ref.

### PRC-003 — Purchase request

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** prc_purchase_requisition.

**Fields only:** requester_name, request_date, requested_items, business_justification, required_by_date, estimated_cost_amount, estimated_cost_currency.

**Identity fields:** requester_name.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

### PRC-008 — Supplier quotation

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** prc_supplier_quotation_capture.

**Fields only:** transaction_reference, transaction_date, counterparty_name, quoted_items, total_amount, total_currency, quotation_validity.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

# 02 · Business and governance

## FIN — Finance accounting and expenses (3 templates)

Shared category context: organization_ref, accounting_period, currency_code.

### FIN-001 — Invoice

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** fin_invoice_ocr_intake.

**Fields only:** invoice_number, supplier_name, invoice_date, total_amount, total_currency, tax_amount, tax_currency.

**Identity fields:** invoice_number.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

### FIN-002 — Receipt

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** fin_receipt_ocr_intake.

**Fields only:** transaction_reference, merchant_name, receipt_date, receipt_total, receipt_total_currency, payment_method.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

### FIN-003 — Expense claim

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** fin_expense_claim.

**Fields only:** requester_name, request_date, expense_category, business_purpose, estimated_cost_amount, estimated_cost_currency, supporting_receipts.

**Identity fields:** requester_name.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

## AUD — Audit risk and compliance (3 templates)

Shared category context: organization_ref, audit_or_review_ref, process_owner.

### AUD-003 — Risk assessment

**Type:** Assessment / analysis · **Shared pack:** ASSESS.

**Stable key:** aud_risk_assessment_worksheet.

**Fields only:** assessment_date, risk_event, likelihood_basis, impact_basis, risk_rating, review_conclusion.

**Identity fields:** risk_event, assessment_date.

**Capture:** Documents; observations; photos; measurements.

**AI assistance:** Extract evidence; organize comparisons; calculate only with declared methods; propose review notes.

**Potential outputs:** Assessment worksheet; findings report; evidence appendix.

**Review:** Reviewer verifies evidence, assumptions and conclusions.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### AUD-013 — Audit finding

**Type:** Case-management workflow · **Shared pack:** CASE.

**Stable key:** aud_audit_finding_record.

**Fields only:** case_reference, case_opened_date, criteria, observed_condition, cause, effect, followup_actions.

**Identity fields:** case_reference.

**Capture:** Forms; documents; consented media; messages.

**AI assistance:** Summarize supplied evidence; extract dates; suggest routing; redact selected copies.

**Potential outputs:** Case file; chronology; action list; closure report.

**Review:** Authorized handler; restricted access; no automated adverse decision.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

### AUD-019 — Compliance check

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** aud_compliance_evidence_checklist.

**Fields only:** check_date, obligation_reference, required_evidence, verification_result, exceptions, corrective_actions.

**Identity fields:** obligation_reference.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

## LEG — Legal contracts and governance (2 templates)

Shared category context: organization_ref, matter_ref, jurisdiction.

### LEG-002 — Contract record

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** leg_contract_metadata_extraction.

**Fields only:** entry_identifier, record_subject, contract_parties, effective_date, key_obligations, review_due_date, source_reference.

**Identity fields:** entry_identifier.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Restricted · **Rollout:** P1 · Expansion.

### LEG-030 — Legal deadline

**Type:** Tracker / follow-up · **Shared pack:** TRACK.

**Stable key:** leg_legal_deadline_tracker.

**Fields only:** matter_ref, tracked_item, deadline_basis, target_date, responsible_counsel, current_stage, latest_update.

**Identity fields:** tracked_item.

**Capture:** Linked records; manual updates; imported events.

**AI assistance:** Extract dates and commitments; propose status updates with evidence.

**Potential outputs:** Tracker; overdue list; follow-up draft; completion report.

**Review:** Status changes must be confirmed or tied to a trusted event.

**Default privacy:** Restricted · **Rollout:** P1 · Expansion.

## HR — Human resources and workforce (3 templates)

Shared category context: organization_ref, department_ref, person_ref.

### HR-010 — Employee record

**Type:** Profile / intake · **Shared pack:** PROFILE.

**Stable key:** hr_employee_master_record.

**Fields only:** employment_identifier, display_name, department_ref, phone_primary, email_address, employment_terms.

**Identity fields:** display_name.

**Capture:** Manual entry; approved documents; contact imports.

**AI assistance:** Extract supplied profile data; flag conflicts; reuse only approved facts.

**Potential outputs:** Profile card; directory entry; intake summary.

**Review:** Collect only necessary personal data; obtain required permissions.

**Default privacy:** Restricted · **Rollout:** P1 · Expansion.

### HR-013 — Timesheet entry

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** hr_timesheet.

**Fields only:** person_ref, activity_date, work_activity, start_time, end_time, hours_worked, project_allocation.

**Identity fields:** person_ref, activity_date, start_time.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Restricted · **Rollout:** P1 · Expansion.

### HR-014 — Leave request

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** hr_leave_request.

**Fields only:** requester_name, request_date, leave_type, leave_start_date, leave_end_date, decision.

**Identity fields:** requester_name.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Restricted · **Rollout:** P1 · Expansion.

# 03 · Collaboration and delivery

## MGT — Projects programs and strategy (3 templates)

Shared category context: organization_ref, program_ref, project_ref.

### MGT-005 — Project plan

**Type:** Plan / schedule · **Shared pack:** PLAN.

**Stable key:** mgt_project_schedule.

**Fields only:** plan_title, planning_objective, activities, responsible_roles, start_date, end_date, plan_status.

**Identity fields:** plan_title.

**Capture:** Manual entry; existing records; requirement documents.

**AI assistance:** Organize activities; draft a sequence; surface dependencies and missing assumptions.

**Potential outputs:** Plan; schedule; assignment table; planning brief.

**Review:** Owner confirms dates, resources and assumptions.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

### MGT-009 — Project issue

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** mgt_project_issue_log.

**Fields only:** project_ref, issue_description, priority, resolution_owner, entry_status, review_due_date.

**Identity fields:** project_ref.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

### MGT-012 — Project progress update

**Type:** Generated report · **Shared pack:** REPORT.

**Stable key:** mgt_project_status_update.

**Fields only:** project_ref, period_start_date, period_end_date, progress_summary, blocked_work, next_steps.

**Identity fields:** project_ref.

**Capture:** Reviewed records; source documents; approved metrics.

**AI assistance:** Aggregate verified data; draft narrative; cite evidence and disclose gaps.

**Potential outputs:** Report draft; tables; annexes; management summary.

**Review:** Human verifies calculations, claims and professional judgments.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

## MTG — Meetings events and coordination (2 templates)

Shared category context: organization_ref, event_ref, organizer_ref.

### MTG-006 — Meeting record

**Type:** Meeting / collaboration · **Shared pack:** MEET.

**Stable key:** mtg_meeting_notes_capture.

**Fields only:** meeting_title, meeting_date, attendees, agenda, discussion_notes, decisions, actions.

**Identity fields:** meeting_title, meeting_date.

**Capture:** Manual notes; explicitly consented audio; uploaded files.

**AI assistance:** Transcribe; propose speaker labels; summarize; extract candidate decisions and action owners.

**Potential outputs:** Minutes draft; attendance register; action tracker; follow-up draft.

**Review:** Participants or chair confirm decisions and attributions.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.

### MTG-024 — Visitor sign-in

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** mtg_visitor_sign_in.

**Fields only:** visitor_name, host, visit_purpose, effective_date, site_name.

**Identity fields:** visitor_name.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

## GRT — Grants proposals and fundraising (3 templates)

Shared category context: organization_ref, opportunity_ref, funding_source_ref.

### GRT-001 — Funding opportunity

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** grt_funding_opportunity_intake.

**Fields only:** funder_name, opportunity_title, closing_at, source_reference, entry_status.

**Identity fields:** funder_name.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

### GRT-012 — Grant proposal

**Type:** Proposal-generation workflow · **Shared pack:** PROPOSAL.

**Stable key:** grt_full_grant_proposal.

**Fields only:** proposal_title, funder_name, submission_deadline_date, project_objectives, methodology, workplan, budget_amount, budget_currency.

**Identity fields:** funder_name.

**Capture:** Terms of reference; company profile; cost inputs; approved branding.

**AI assistance:** Extract requirements; map evidence; draft sections; flag unsupported claims and unmet criteria.

**Potential outputs:** Proposal draft; budget; compliance matrix; submission checklist.

**Review:** No invented eligibility, qualifications, clients, outcomes, costs or signatures.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

### GRT-038 — Donation pledge

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** grt_donation_pledge_register.

**Fields only:** donor_reference, effective_date, pledged_amount, pledged_currency, payment_schedule, entry_status.

**Identity fields:** donor_reference.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

## CRM — Sales service and marketing (3 templates)

Shared category context: organization_ref, customer_or_account_ref, campaign_ref.

### CRM-001 — Sales lead

**Type:** Profile / intake · **Shared pack:** PROFILE.

**Stable key:** crm_sales_lead_capture.

**Fields only:** lead_name, phone_primary, email_address, interest_area, contact_permission.

**Identity fields:** lead_name.

**Capture:** Manual entry; approved documents; contact imports.

**AI assistance:** Extract supplied profile data; flag conflicts; reuse only approved facts.

**Potential outputs:** Profile card; directory entry; intake summary.

**Review:** Collect only necessary personal data; obtain required permissions.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### CRM-011 — Customer service request

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** crm_service_request_intake.

**Fields only:** requester_name, request_date, requested_service, urgency, preferred_channel, decision.

**Identity fields:** requester_name.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### CRM-015 — Customer feedback

**Type:** Survey / questionnaire · **Shared pack:** SURVEY.

**Stable key:** crm_customer_satisfaction_survey.

**Fields only:** customer_or_account_ref, interview_date, service_rating, feedback_reason, improvement_request.

**Identity fields:** customer_or_account_ref.

**Capture:** Manual interviews; self-completion; consented audio; optional GPS.

**AI assistance:** Transcribe responses; classify open answers for review; summarize aggregate data.

**Potential outputs:** Response dataset; survey summary; coded response table.

**Review:** Preserve consent and sampling limits; do not infer sensitive traits.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

# 04 · Health and life sciences

## HOP — Hospital and biomedical operations (3 templates)

Shared category context: facility_ref, department_ref, service_unit.

### HOP-001 — Health facility record

**Type:** Profile / intake · **Shared pack:** PROFILE.

**Stable key:** hop_hospital_facility_profile.

**Fields only:** facility_ref, display_name, facility_level, service_packages, operating_hours, phone_primary.

**Identity fields:** display_name.

**Capture:** Manual entry; approved documents; contact imports.

**AI assistance:** Extract supplied profile data; flag conflicts; reuse only approved facts.

**Potential outputs:** Profile card; directory entry; intake summary.

**Review:** Collect only necessary personal data; obtain required permissions.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### HOP-005 — Medical equipment inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** hop_biomedical_service_inspection.

**Fields only:** device_identifier, inspection_date, service_manual_ref, observed_condition, defects, inspection_result, recommended_actions.

**Identity fields:** device_identifier.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### HOP-010 — Sterilizer cycle record

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** hop_autoclave_cycle_record.

**Fields only:** cycle_identifier, load_reference, activity_date, temperature_c, cycle_duration_min, outcome.

**Identity fields:** cycle_identifier.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## CLN — Clinical care and patient services (4 templates)

Shared category context: facility_ref, patient_pseudonymous_ref, encounter_ref.

### CLN-001 — Patient registration

**Type:** Profile / intake · **Shared pack:** PROFILE.

**Stable key:** cln_patient_registration_intake.

**Fields only:** patient_identifier, display_name, phone_primary, contact_preferences, identity_verification.

**Identity fields:** display_name.

**Capture:** Manual entry; approved documents; contact imports.

**AI assistance:** Extract supplied profile data; flag conflicts; reuse only approved facts.

**Potential outputs:** Profile card; directory entry; intake summary.

**Review:** Collect only necessary personal data; obtain required permissions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### CLN-003 — Clinical encounter note

**Type:** Case-management workflow · **Shared pack:** CASE.

**Stable key:** cln_clinical_encounter_documentation.

**Fields only:** patient_pseudonymous_ref, case_opened_date, presenting_concerns, clinician_observations, clinician_plan, next_followup_date.

**Identity fields:** patient_pseudonymous_ref.

**Capture:** Forms; documents; consented media; messages.

**AI assistance:** Summarize supplied evidence; extract dates; suggest routing; redact selected copies.

**Potential outputs:** Case file; chronology; action list; closure report.

**Review:** Authorized handler; restricted access; no automated adverse decision.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### CLN-005 — Vital sign measurement

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** cln_vital_signs_recording.

**Fields only:** patient_pseudonymous_ref, measurement_type, measured_value, measurement_unit, measurement_date, measurement_time, device_reference.

**Identity fields:** measurement_type, measurement_date.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### CLN-010 — Clinical referral

**Type:** Generated document · **Shared pack:** DOC.

**Stable key:** cln_clinical_referral_document.

**Fields only:** patient_pseudonymous_ref, referral_reason, verified_findings, receiving_service, document_reference.

**Identity fields:** document_reference.

**Capture:** Documents; source records; approved brand assets.

**AI assistance:** Build required structure; draft source-linked content; flag missing inputs.

**Potential outputs:** Document draft; PDF or DOCX export; evidence index.

**Review:** Review all facts, professional conclusions, formatting and signatures.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## LAB — Laboratories and diagnostics (3 templates)

Shared category context: laboratory_ref, sample_or_run_ref, method_ref.

### LAB-001 — Laboratory sample

**Type:** Sample / chain-of-custody · **Shared pack:** SAMPLE.

**Stable key:** lab_laboratory_sample_registration.

**Fields only:** sample_identifier, sample_type, collection_date, collection_time, collection_location, requested_tests, sample_condition.

**Identity fields:** sample_identifier.

**Capture:** Barcode; field entry; optional GPS; labels; custody documents.

**AI assistance:** Read sample labels; prepare custody paperwork; flag mismatches.

**Potential outputs:** Sample register; chain-of-custody form; laboratory request.

**Review:** Qualified sampling protocols and custody confirmation required.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### LAB-007 — Laboratory result review

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** lab_test_result_transcription_review.

**Fields only:** sample_or_run_ref, check_date, test_name, measured_value, measurement_unit, source_report.

**Identity fields:** sample_or_run_ref.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### LAB-011 — Laboratory quality-control reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** lab_quality_control_run_record.

**Fields only:** control_material, measurement_type, measured_value, measurement_unit, measurement_date, control_limits_ref, within_threshold.

**Identity fields:** measurement_type, measurement_date.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## PHM — Pharmacy and life sciences operations (3 templates)

Shared category context: organization_ref, product_ref, batch_ref.

### PHM-001 — Medicine record

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** phm_pharmaceutical_product_catalogue.

**Fields only:** product_ref, product_name, strength_value, strength_unit, dosage_form, manufacturer_name.

**Identity fields:** product_ref.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### PHM-003 — Medicine dispensing record

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** phm_medicine_dispensing_documentation.

**Fields only:** product_ref, batch_ref, transaction_date, authorized_order_ref, dispensed_quantity, dispensed_quantity_unit, authorized_dispenser.

**Identity fields:** product_ref.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### PHM-008 — Suspected medicine reaction

**Type:** Incident workflow · **Shared pack:** INCIDENT.

**Stable key:** phm_pharmacovigilance_report_intake.

**Fields only:** suspected_product, event_date, reported_event, severity, immediate_action, reported_by_name.

**Identity fields:** reported_by_name.

**Capture:** Photos; explicit audio notes; manual observations; documents.

**AI assistance:** Transcribe reports; build timeline; separate observations from allegations and inferred causes.

**Potential outputs:** Incident report; evidence log; response actions; follow-up record.

**Review:** Qualified review for high-impact incidents; do not infer blame.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## PHE — Public health and surveillance (3 templates)

Shared category context: program_ref, reporting_area, reporting_period.

### PHE-003 — Disease surveillance report

**Type:** Case-management workflow · **Shared pack:** CASE.

**Stable key:** phe_disease_surveillance_report_intake.

**Fields only:** reporting_area, reporting_period, disease_name, reported_case_count, reporting_source, qualified_review.

**Identity fields:** disease_name.

**Capture:** Forms; documents; consented media; messages.

**AI assistance:** Summarize supplied evidence; extract dates; suggest routing; redact selected copies.

**Potential outputs:** Case file; chronology; action list; closure report.

**Review:** Authorized handler; restricted access; no automated adverse decision.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### PHE-007 — Vaccination session tally

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** phe_vaccination_campaign_tally.

**Fields only:** session_reference, activity_date, reporting_area, vaccine_name, dose_count, stock_reconciliation.

**Identity fields:** session_reference.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### PHE-008 — Health outreach session

**Type:** Meeting / collaboration · **Shared pack:** MEET.

**Stable key:** phe_health_promotion_session_record.

**Fields only:** session_topic, meeting_date, meeting_venue, attendees_count, materials_used, actions.

**Identity fields:** session_topic, meeting_date.

**Capture:** Manual notes; explicitly consented audio; uploaded files.

**AI assistance:** Transcribe; propose speaker labels; summarize; extract candidate decisions and action owners.

**Potential outputs:** Minutes draft; attendance register; action tracker; follow-up draft.

**Review:** Participants or chair confirm decisions and attributions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

# 05 · Education research and care

## EDU — Schools and vocational learning (3 templates)

Shared category context: institution_ref, class_or_course_ref, academic_period.

### EDU-003 — Learner enrollment

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** edu_student_enrollment_register.

**Fields only:** enrollment_reference, record_subject, class_assignment, academic_period, enrollment_status.

**Identity fields:** enrollment_reference.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### EDU-005 — Learner attendance

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** edu_daily_learner_attendance.

**Fields only:** student_reference, attendance_date, class_or_course_ref, attendance_status, observations.

**Identity fields:** student_reference.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### EDU-011 — Learner assessment score

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** edu_learner_assessment_results.

**Fields only:** student_reference, class_or_course_ref, assessment_reference, measured_value, measurement_unit, measurement_date, teacher_review.

**Identity fields:** student_reference, assessment_reference.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## HED — Higher education and training (2 templates)

Shared category context: institution_ref, program_ref, academic_period.

### HED-004 — Credential verification

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** hed_credential_verification_record.

**Fields only:** credential_reference, issuing_source, check_date, verification_result, reviewer_name.

**Identity fields:** credential_reference.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### HED-014 — Internship supervision visit

**Type:** Visit / field workflow · **Shared pack:** VISIT.

**Stable key:** hed_internship_supervision_visit.

**Fields only:** student_reference, visited_site_or_party, visit_date, learning_activities, supervisor_feedback, agreed_actions.

**Identity fields:** visited_site_or_party, visit_date.

**Capture:** Field forms; photos; explicit audio notes; optional GPS.

**AI assistance:** Transcribe notes; organize evidence; draft visit findings and follow-up.

**Potential outputs:** Visit report; photo appendix; action tracker.

**Review:** Field officer verifies observations and any attributed statements.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## RES — Research and knowledge management (3 templates)

Shared category context: research_project_ref, study_ref, protocol_version.

### RES-004 — Research consent record

**Type:** Agreement / approval · **Shared pack:** AGREEMENT.

**Stable key:** res_research_consent_record.

**Fields only:** study_ref, first_party_name, approved_consent_version, consent_status, effective_date, approval_evidence.

**Identity fields:** study_ref.

**Capture:** Documents; manual entry; explicit acknowledgements.

**AI assistance:** Extract clauses and dates; compare with approved wording; prepare a source-grounded draft.

**Potential outputs:** Agreement draft; obligations register; signed-evidence index.

**Review:** Authorized signatory; legal review where applicable.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### RES-011 — Experiment run

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** res_experiment_run_log.

**Fields only:** run_identifier, protocol_version, activity_date, conditions, observations, outcome.

**Identity fields:** run_identifier.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### RES-018 — Literature evidence note

**Type:** Assessment / analysis · **Shared pack:** ASSESS.

**Stable key:** res_literature_evidence_extraction.

**Fields only:** source_citation, assessment_objective, study_findings, quality_notes, assessment_date.

**Identity fields:** source_citation.

**Capture:** Documents; observations; photos; measurements.

**AI assistance:** Extract evidence; organize comparisons; calculate only with declared methods; propose review notes.

**Potential outputs:** Assessment worksheet; findings report; evidence appendix.

**Review:** Reviewer verifies evidence, assumptions and conclusions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## SOC — Social care and community services (3 templates)

Shared category context: service_organization_ref, case_ref, service_area.

### SOC-002 — Household needs assessment

**Type:** Assessment / analysis · **Shared pack:** ASSESS.

**Stable key:** soc_household_needs_assessment.

**Fields only:** case_ref, assessment_date, household_priorities, available_support, service_gaps, review_conclusion.

**Identity fields:** case_ref.

**Capture:** Documents; observations; photos; measurements.

**AI assistance:** Extract evidence; organize comparisons; calculate only with declared methods; propose review notes.

**Potential outputs:** Assessment worksheet; findings report; evidence appendix.

**Review:** Reviewer verifies evidence, assumptions and conclusions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### SOC-003 — Social care visit

**Type:** Visit / field workflow · **Shared pack:** VISIT.

**Stable key:** soc_social_worker_home_visit.

**Fields only:** case_ref, visit_date, visit_consent, observed_needs, agreed_actions, next_visit_date.

**Identity fields:** case_ref, visit_date.

**Capture:** Field forms; photos; explicit audio notes; optional GPS.

**AI assistance:** Transcribe notes; organize evidence; draft visit findings and follow-up.

**Potential outputs:** Visit report; photo appendix; action tracker.

**Review:** Field officer verifies observations and any attributed statements.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### SOC-005 — Social service referral

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** soc_service_referral_form.

**Fields only:** case_ref, request_date, consented_referral_purpose, receiving_service, minimum_details, decision.

**Identity fields:** case_ref.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

# 06 · Buildings land and infrastructure

## REA — Real estate property and valuation (3 templates)

Shared category context: property_ref, site_ref, inspection_or_valuation_date.

### REA-001 — Property record

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** rea_property_master_record.

**Fields only:** property_ref, item_name, property_type, street_address, ownership_reference.

**Identity fields:** property_ref.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### REA-003 — Building condition inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** rea_building_condition_survey.

**Fields only:** property_ref, inspection_date, building_elements, condition_grade, condition_findings, recommended_actions.

**Identity fields:** property_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Confidential · **Rollout:** P0 · Foundation.

### REA-015 — Rent payment

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** rea_rent_collection_log.

**Fields only:** property_ref, counterparty_name, rental_period, transaction_date, total_amount, total_currency, receipt_reference.

**Identity fields:** property_ref.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

## CON — Construction and engineering projects (3 templates)

Shared category context: project_ref, site_ref, work_package_ref.

### CON-002 — Construction site diary

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** con_construction_daily_site_diary.

**Fields only:** site_ref, activity_date, work_performed, participants_count, weather_observed, observations.

**Identity fields:** site_ref, activity_date.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

### CON-009 — Construction material inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** con_material_delivery_inspection.

**Fields only:** site_ref, inspection_date, delivery_reference, material_condition, acceptance_result, defects.

**Identity fields:** site_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

### CON-034 — Construction defect

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** con_snag_or_punch_list.

**Fields only:** site_ref, entry_identifier, defect_location, required_correction, responsible_role, entry_status, closure_evidence.

**Identity fields:** entry_identifier.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

## CIV — Civil infrastructure and public works (3 templates)

Shared category context: infrastructure_ref, network_or_corridor_ref, inspection_date.

### CIV-002 — Road condition inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** civ_road_condition_survey.

**Fields only:** infrastructure_ref, inspection_date, location_reference, condition_grade, surface_distress, drainage_condition, recommended_actions.

**Identity fields:** infrastructure_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

### CIV-014 — Traffic count

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** civ_road_traffic_count.

**Fields only:** count_location, measurement_date, measurement_time, measurement_type, vehicle_count, count_interval.

**Identity fields:** measurement_type, measurement_date.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

### CIV-022 — Public infrastructure service request

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** civ_public_works_service_request.

**Fields only:** infrastructure_ref, request_date, requester_name, infrastructure_issue, location, supporting_photos.

**Identity fields:** infrastructure_ref.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Internal · **Rollout:** P1 · Expansion.

## GIS — Land surveying mapping and planning (3 templates)

Shared category context: survey_project_ref, parcel_or_feature_ref, coordinate_reference_system.

### GIS-001 — Land parcel record

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** gis_land_parcel_field_record.

**Fields only:** parcel_identifier, record_subject, observed_use, boundary_evidence, source_reference.

**Identity fields:** parcel_identifier.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### GIS-004 — Survey point

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** gis_gnss_survey_point_capture.

**Fields only:** point_reference, parcel_or_feature_ref, coordinate_reference_system, gps_latitude, gps_longitude, gps_accuracy_m, measurement_date, fix_quality.

**Identity fields:** point_reference.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### GIS-007 — Land use observation

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Stable key:** gis_land_use_observation.

**Fields only:** parcel_or_feature_ref, observed_land_use, observation_date, factual_description, feature_extent.

**Identity fields:** parcel_or_feature_ref.

**Capture:** Photos; explicit audio captions; video; optional GPS and time.

**AI assistance:** OCR or transcribe visible evidence; propose tags and captions; retain source links.

**Potential outputs:** Observation record; photo sheet; annotated evidence bundle.

**Review:** Observed, reported and inferred details must remain distinguishable.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

# 07 · Agriculture and natural resources

## AGR — Crops farms and agribusiness (4 templates)

Shared category context: farm_ref, plot_ref, production_season.

### AGR-007 — Crop planting

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** agr_planting_record.

**Fields only:** plot_ref, production_season, seed_variety, planting_date, planted_area, observations.

**Identity fields:** plot_ref.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### AGR-010 — Crop input application

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** agr_crop_input_application_log.

**Fields only:** plot_ref, activity_date, input_product, applied_quantity, applied_quantity_unit, approved_application_ref, observations.

**Identity fields:** plot_ref, input_product, activity_date.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### AGR-013 — Crop condition observation

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Stable key:** agr_crop_scouting_observation.

**Fields only:** plot_ref, observed_at, crop_stage, observed_symptoms, verification_status, verification_notes.

**Identity fields:** plot_ref, observed_at.

**Capture:** Photos; explicit audio captions; video; optional GPS and time.

**AI assistance:** OCR or transcribe visible evidence; propose tags and captions; retain source links.

**Potential outputs:** Observation record; photo sheet; annotated evidence bundle.

**Review:** Observed, reported and inferred details must remain distinguishable.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### AGR-020 — Crop harvest

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** agr_harvest_collection_record.

**Fields only:** plot_ref, production_season, harvest_date, crop_quantity, crop_quantity_unit, quality_grade_basis.

**Identity fields:** plot_ref.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

## LIV — Livestock veterinary and animal care (3 templates)

Shared category context: farm_or_care_site_ref, animal_or_herd_ref, production_period.

### LIV-002 — Animal identification

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** liv_animal_identification_record.

**Fields only:** tag_identifier, species, breed, farm_or_care_site_ref, condition_grade, condition_note.

**Identity fields:** tag_identifier.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### LIV-009 — Animal health observation

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Stable key:** liv_animal_health_observation.

**Fields only:** animal_or_herd_ref, farm_or_care_site_ref, observed_at, observed_symptoms, veterinary_referral, verification_notes.

**Identity fields:** animal_or_herd_ref, observed_at.

**Capture:** Photos; explicit audio captions; video; optional GPS and time.

**AI assistance:** OCR or transcribe visible evidence; propose tags and captions; retain source links.

**Potential outputs:** Observation record; photo sheet; annotated evidence bundle.

**Review:** Observed, reported and inferred details must remain distinguishable.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### LIV-015 — Milk collection

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** liv_dairy_milk_collection.

**Fields only:** farm_or_care_site_ref, animal_or_herd_ref, collection_date, milk_volume, quality_test_ref.

**Identity fields:** farm_or_care_site_ref.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## AQU — Fisheries aquaculture and beekeeping (4 templates)

Shared category context: enterprise_ref, production_site_ref, production_cycle.

### AQU-003 — Fish stocking

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** aqu_aquaculture_stocking_record.

**Fields only:** production_site_ref, production_cycle, species, fingerling_count, stocking_date, counterparty_name.

**Identity fields:** production_site_ref.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### AQU-011 — Fish harvest

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** aqu_fish_harvest_record.

**Fields only:** production_site_ref, production_cycle, harvest_batch, harvest_weight, harvest_date.

**Identity fields:** production_site_ref.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### AQU-024 — Beehive inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** aqu_beehive_inspection.

**Fields only:** production_site_ref, inspection_scope, inspection_date, colony_observations, hive_condition, recommended_actions.

**Identity fields:** production_site_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### AQU-025 — Honey harvest

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** aqu_honey_harvest_record.

**Fields only:** hive_reference, batch_identifier, transaction_date, harvest_quantity, harvest_quantity_unit.

**Identity fields:** hive_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

## FOR — Forestry conservation and biodiversity (3 templates)

Shared category context: landscape_ref, management_unit_ref, survey_period.

### FOR-002 — Tree inventory

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** for_tree_inventory.

**Fields only:** tree_identifier, verified_species, measurement_location, condition_grade, condition_note.

**Identity fields:** tree_identifier.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### FOR-008 — Tree planting

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** for_tree_planting_event_record.

**Fields only:** planting_site, activity_date, species, planted_count, observations.

**Identity fields:** planting_site, activity_date.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### FOR-017 — Species observation

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Stable key:** for_biodiversity_species_observation.

**Fields only:** landscape_ref, observed_at, proposed_species, factual_description, verification_status, expert_verification.

**Identity fields:** landscape_ref, observed_at.

**Capture:** Photos; explicit audio captions; video; optional GPS and time.

**AI assistance:** OCR or transcribe visible evidence; propose tags and captions; retain source links.

**Potential outputs:** Observation record; photo sheet; annotated evidence bundle.

**Review:** Observed, reported and inferred details must remain distinguishable.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

# 08 · Production and industry

## MFG — Manufacturing production and quality (3 templates)

Shared category context: plant_ref, production_line_ref, product_or_batch_ref.

### MFG-005 — Production output

**Type:** Generated report · **Shared pack:** REPORT.

**Stable key:** mfg_production_shift_report.

**Fields only:** production_line_ref, product_or_batch_ref, period_start_date, produced_quantity, produced_quantity_unit, rejected_quantity, rejected_quantity_unit, line_constraints.

**Identity fields:** production_line_ref.

**Capture:** Reviewed records; source documents; approved metrics.

**AI assistance:** Aggregate verified data; draft narrative; cite evidence and disclose gaps.

**Potential outputs:** Report draft; tables; annexes; management summary.

**Review:** Human verifies calculations, claims and professional judgments.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### MFG-012 — Process parameter reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** mfg_process_parameter_log.

**Fields only:** product_or_batch_ref, measurement_date, measurement_time, parameter_name, observed_value, observed_value_unit, approved_limit_ref.

**Identity fields:** product_or_batch_ref, parameter_name, measurement_date, measurement_time.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### MFG-013 — Production defect

**Type:** Incident workflow · **Shared pack:** INCIDENT.

**Stable key:** mfg_manufacturing_defect_report.

**Fields only:** product_or_batch_ref, event_date, defect_type, affected_quantity, affected_quantity_unit, factual_description, containment_action.

**Identity fields:** product_or_batch_ref.

**Capture:** Photos; explicit audio notes; manual observations; documents.

**AI assistance:** Transcribe reports; build timeline; separate observations from allegations and inferred causes.

**Potential outputs:** Incident report; evidence log; response actions; follow-up record.

**Review:** Qualified review for high-impact incidents; do not infer blame.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

## FOD — Food beverage and processing (3 templates)

Shared category context: food_business_ref, production_site_ref, batch_ref.

### FOD-006 — Food production batch

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** fod_food_production_batch_sheet.

**Fields only:** batch_ref, activity_date, ingredient_lots, production_steps_ref, output_quantity, output_quantity_unit, observations.

**Identity fields:** batch_ref.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### FOD-007 — Food temperature reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** fod_food_processing_temperature_log.

**Fields only:** batch_ref, process_step, measurement_date, measurement_time, temperature_reading, approved_critical_limit_ref, quality_flag.

**Identity fields:** batch_ref, measurement_date, measurement_time.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### FOD-012 — Food hygiene inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** fod_food_hygiene_inspection.

**Fields only:** production_site_ref, inspection_date, hygiene_criteria, observed_conditions, corrective_actions, inspection_result.

**Identity fields:** production_site_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## TEX — Apparel textiles crafts and materials (3 templates)

Shared category context: workshop_or_factory_ref, order_ref, product_style_ref.

### TEX-003 — Tailoring order

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** tex_tailoring_order_intake.

**Fields only:** request_reference, requester_name, garment_description, agreed_design, delivery_date, estimated_cost_amount, estimated_cost_currency.

**Identity fields:** request_reference.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### TEX-004 — Fabric roll inventory

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** tex_fabric_roll_inventory.

**Fields only:** roll_identifier, fabric_type, usable_length, workshop_or_factory_ref, condition_grade.

**Identity fields:** roll_identifier.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### TEX-010 — Garment inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** tex_garment_final_inspection.

**Fields only:** product_style_ref, inspection_date, approved_specification, observed_length_mm, observed_width_mm, acceptance_result, defects.

**Identity fields:** product_style_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

## MIN — Mining quarrying and geology (3 templates)

Shared category context: site_ref, operation_ref, geological_or_material_ref.

### MIN-002 — Rock observation

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Stable key:** min_geological_outcrop_observation.

**Fields only:** site_ref, observed_at, location, rock_description, geologist_notes.

**Identity fields:** site_ref, observed_at.

**Capture:** Photos; explicit audio captions; video; optional GPS and time.

**AI assistance:** OCR or transcribe visible evidence; propose tags and captions; retain source links.

**Potential outputs:** Observation record; photo sheet; annotated evidence bundle.

**Review:** Observed, reported and inferred details must remain distinguishable.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### MIN-003 — Geological sample

**Type:** Sample / chain-of-custody · **Shared pack:** SAMPLE.

**Stable key:** min_geological_sample_collection.

**Fields only:** sample_identifier, sample_type, collection_date, location, sampling_method, sample_condition, requested_tests.

**Identity fields:** sample_identifier.

**Capture:** Barcode; field entry; optional GPS; labels; custody documents.

**AI assistance:** Read sample labels; prepare custody paperwork; flag mismatches.

**Potential outputs:** Sample register; chain-of-custody form; laboratory request.

**Review:** Qualified sampling protocols and custody confirmation required.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### MIN-008 — Quarry production

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** min_quarry_production_log.

**Fields only:** site_ref, activity_date, material_type, produced_quantity, produced_quantity_unit, measurement_basis.

**Identity fields:** site_ref, material_type, activity_date.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

# 09 · Energy utilities and environment

## ENE — Power renewable energy and electrical (2 templates)

Shared category context: operator_ref, energy_site_ref, asset_or_meter_ref.

### ENE-004 — Solar installation inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** ene_solar_installation_inspection.

**Fields only:** energy_site_ref, inspection_date, approved_design, observed_installation, defects, qualified_test_ref, inspection_result.

**Identity fields:** energy_site_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### ENE-012 — Electricity meter reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** ene_electricity_meter_reading.

**Fields only:** meter_identifier, energy_site_ref, measured_value, measurement_unit, reading_at, quality_flag.

**Identity fields:** meter_identifier.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

## OIL — Oil gas and fuel operations (2 templates)

Shared category context: operator_ref, facility_ref, asset_or_shipment_ref.

### OIL-002 — Fuel tank reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** oil_fuel_tank_level_reading.

**Fields only:** tank_reference, measurement_date, measurement_time, measured_value, measurement_unit, measurement_method.

**Identity fields:** tank_reference, measurement_date, measurement_time.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### OIL-003 — Fuel delivery receipt

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** oil_fuel_delivery_receipt.

**Fields only:** transaction_reference, transaction_date, facility_ref, supplier_reference, delivered_volume, delivery_document.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## WAT — Water sanitation and irrigation (3 templates)

Shared category context: service_provider_ref, system_ref, site_or_sampling_point.

### WAT-001 — Water source inventory

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** wat_water_source_inventory.

**Fields only:** item_identifier, item_name, source_type, source_location, condition_grade, condition_note.

**Identity fields:** item_identifier.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### WAT-005 — Water meter reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** wat_water_meter_reading.

**Fields only:** meter_identifier, system_ref, measured_value, measurement_unit, reading_date, quality_flag.

**Identity fields:** meter_identifier.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### WAT-011 — Water sample collection

**Type:** Sample / chain-of-custody · **Shared pack:** SAMPLE.

**Stable key:** wat_drinking_water_sample_collection.

**Fields only:** sample_identifier, sampling_point, collection_date, sampling_time, sample_condition, test_panel.

**Identity fields:** sample_identifier.

**Capture:** Barcode; field entry; optional GPS; labels; custody documents.

**AI assistance:** Read sample labels; prepare custody paperwork; flag mismatches.

**Potential outputs:** Sample register; chain-of-custody form; laboratory request.

**Review:** Qualified sampling protocols and custody confirmation required.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

## WST — Waste recycling and circular economy (3 templates)

Shared category context: operator_ref, service_area_ref, material_stream.

### WST-003 — Waste collection

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** wst_waste_collection_completion.

**Fields only:** collection_location, activity_date, material_stream, collected_quantity, collected_quantity_unit, service_exception.

**Identity fields:** collection_location, activity_date.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### WST-005 — Waste container inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** wst_waste_bin_condition_inspection.

**Fields only:** container_reference, inspection_date, service_area_ref, visible_condition, replacement_need.

**Identity fields:** container_reference.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### WST-010 — Recyclable material purchase

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** wst_recyclable_materials_purchase.

**Fields only:** transaction_date, counterparty_name, material_type, accepted_weight, agreed_price, agreed_price_currency.

**Identity fields:** counterparty_name.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

# 10 · Transport and supply chains

## FLT — Vehicles fleets and road transport (3 templates)

Shared category context: fleet_ref, vehicle_ref, trip_or_service_ref.

### FLT-001 — Vehicle inventory

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** flt_vehicle_master_inventory.

**Fields only:** registration_number, vehicle_identification_number, make, model, condition_grade, custodian_name.

**Identity fields:** registration_number.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### FLT-006 — Vehicle pre-trip inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** flt_vehicle_daily_pre_trip_inspection.

**Fields only:** vehicle_ref, inspection_date, approved_checklist, odometer_km, defects, defect_restrictions, inspection_result.

**Identity fields:** vehicle_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### FLT-008 — Vehicle journey

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** flt_vehicle_journey_log.

**Fields only:** vehicle_ref, origin, destination, departure_at, arrival_at, participants_or_operators, observations.

**Identity fields:** vehicle_ref.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## LOG — Logistics freight and distribution (3 templates)

Shared category context: operator_ref, shipment_ref, customer_ref.

### LOG-001 — Shipment booking

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** log_shipment_booking.

**Fields only:** shipment_ref, customer_ref, request_date, origin, destination, cargo_description, required_by_date.

**Identity fields:** shipment_ref.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### LOG-013 — Delivery confirmation

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** log_last_mile_delivery_proof.

**Fields only:** order_reference, shipment_ref, counterparty_name, delivery_at, recipient_confirmation, source_documents.

**Identity fields:** order_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### LOG-015 — Cargo damage inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** log_cargo_damage_survey.

**Fields only:** cargo_reference, inspection_date, observed_damage, survey_limitations, recommended_actions, inspection_result.

**Identity fields:** cargo_reference.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## AVI — Aviation airports and drone administration (2 templates)

Shared category context: operator_ref, aircraft_or_airport_ref, operation_ref.

### AVI-004 — Aircraft defect report

**Type:** Incident workflow · **Shared pack:** INCIDENT.

**Stable key:** avi_aircraft_defect_reporting.

**Fields only:** incident_reference, aircraft_reference, event_date, reported_defect, severity, licensed_review.

**Identity fields:** incident_reference.

**Capture:** Photos; explicit audio notes; manual observations; documents.

**AI assistance:** Transcribe reports; build timeline; separate observations from allegations and inferred causes.

**Potential outputs:** Incident report; evidence log; response actions; follow-up record.

**Review:** Qualified review for high-impact incidents; do not infer blame.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### AVI-025 — Drone flight log

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** avi_drone_flight_log.

**Fields only:** aircraft_or_airport_ref, activity_date, start_time, end_time, authorized_mission, equipment_status.

**Identity fields:** aircraft_or_airport_ref, activity_date, start_time.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## MAR — Maritime ports and inland waterways (2 templates)

Shared category context: operator_ref, vessel_or_port_ref, voyage_ref.

### MAR-001 — Vessel inventory

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** mar_vessel_master_inventory.

**Fields only:** vessel_identifier, vessel_type, registered_capacity, registered_capacity_unit, condition_grade, custodian_name.

**Identity fields:** vessel_identifier.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### MAR-005 — Vessel voyage log

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** mar_vessel_voyage_log.

**Fields only:** vessel_or_port_ref, activity_date, departure_port, arrival_port, start_time, end_time, voyage_events.

**Identity fields:** vessel_or_port_ref, activity_date, start_time.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## RAI — Rail transit and mobility services (2 templates)

Shared category context: operator_ref, network_ref, vehicle_or_station_ref.

### RAI-004 — Rail track inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** rai_rail_track_visual_inspection.

**Fields only:** track_segment, inspection_date, observed_condition, defects, authorized_escalation, inspection_result.

**Identity fields:** track_segment.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

### RAI-011 — Transit passenger count

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** rai_transit_passenger_count.

**Fields only:** route_or_station, measurement_date, measurement_time, count_interval, measured_value, measurement_unit.

**Identity fields:** route_or_station, measurement_date, measurement_time.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Internal · **Rollout:** P2 · Specialist.

# 11 · Digital systems and communications

## SWE — Software product and AI delivery (3 templates)

Shared category context: organization_ref, product_or_project_ref, release_ref.

### SWE-003 — Software feature

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** swe_user_story.

**Fields only:** record_subject, product_or_project_ref, user_role, desired_action, acceptance_criteria, entry_status.

**Identity fields:** product_or_project_ref.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### SWE-016 — Software bug report

**Type:** Incident workflow · **Shared pack:** INCIDENT.

**Stable key:** swe_software_defect_report.

**Fields only:** product_or_project_ref, release_ref, reproduction_steps, expected_behavior, actual_behavior, severity, incident_status.

**Identity fields:** product_or_project_ref.

**Capture:** Photos; explicit audio notes; manual observations; documents.

**AI assistance:** Transcribe reports; build timeline; separate observations from allegations and inferred causes.

**Potential outputs:** Incident report; evidence log; response actions; follow-up record.

**Review:** Qualified review for high-impact incidents; do not infer blame.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### SWE-018 — Software test result

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** swe_test_execution_record.

**Fields only:** test_case_ref, release_ref, check_date, actual_result, overall_result, evidence.

**Identity fields:** test_case_ref.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## ICT — IT service management and infrastructure (2 templates)

Shared category context: organization_ref, service_ref, configuration_item_ref.

### ICT-008 — IT support issue

**Type:** Case-management workflow · **Shared pack:** CASE.

**Stable key:** ict_it_support_incident.

**Fields only:** case_reference, affected_service, reported_symptoms, business_impact, case_stage, assigned_handler_name.

**Identity fields:** case_reference.

**Capture:** Forms; documents; consented media; messages.

**AI assistance:** Summarize supplied evidence; extract dates; suggest routing; redact selected copies.

**Potential outputs:** Case file; chronology; action list; closure report.

**Review:** Authorized handler; restricted access; no automated adverse decision.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### ICT-013 — IT change request

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** ict_it_change_request.

**Fields only:** service_ref, request_date, change_scope, test_evidence, rollback_plan, decision.

**Identity fields:** service_ref.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## CYB — Cybersecurity privacy and data governance (3 templates)

Shared category context: organization_ref, authorized_scope_ref, system_or_dataset_ref.

### CYB-006 — Security incident report

**Type:** Incident workflow · **Shared pack:** INCIDENT.

**Stable key:** cyb_security_incident_intake.

**Fields only:** incident_reference, event_date, event_time, observed_indicators, affected_assets, authorized_response, incident_status.

**Identity fields:** incident_reference.

**Capture:** Photos; explicit audio notes; manual observations; documents.

**AI assistance:** Transcribe reports; build timeline; separate observations from allegations and inferred causes.

**Potential outputs:** Incident report; evidence log; response actions; follow-up record.

**Review:** Qualified review for high-impact incidents; do not infer blame.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### CYB-011 — Access permission review

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** cyb_access_privilege_review.

**Fields only:** system_or_dataset_ref, check_date, assigned_entitlements, business_need, reviewer_decision, reviewer_name.

**Identity fields:** system_or_dataset_ref.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### CYB-019 — Personal data request

**Type:** Case-management workflow · **Shared pack:** CASE.

**Stable key:** cyb_data_subject_request_administration.

**Fields only:** case_reference, case_opened_date, request_type, identity_verification_status, response_scope, case_stage, followup_actions.

**Identity fields:** case_reference.

**Capture:** Forms; documents; consented media; messages.

**AI assistance:** Summarize supplied evidence; extract dates; suggest routing; redact selected copies.

**Potential outputs:** Case file; chronology; action list; closure report.

**Review:** Authorized handler; restricted access; no automated adverse decision.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## TEL — Telecommunications networks and connectivity (3 templates)

Shared category context: operator_ref, network_site_ref, service_or_asset_ref.

### TEL-003 — Telecom site inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** tel_telecom_site_condition_inspection.

**Fields only:** network_site_ref, inspection_date, site_structure, equipment_shelter, observed_defects, recommended_actions.

**Identity fields:** network_site_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### TEL-013 — Internet installation survey

**Type:** Visit / field workflow · **Shared pack:** VISIT.

**Stable key:** tel_telecom_customer_installation_survey.

**Fields only:** visit_date, service_location, connectivity_requirements, installation_constraints, observations, agreed_actions.

**Identity fields:** service_location, visit_date.

**Capture:** Field forms; photos; explicit audio notes; optional GPS.

**AI assistance:** Transcribe notes; organize evidence; draft visit findings and follow-up.

**Potential outputs:** Visit report; photo appendix; action tracker.

**Review:** Field officer verifies observations and any attributed statements.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### TEL-015 — Internet speed test

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** tel_connectivity_speed_test_log.

**Fields only:** test_endpoint, measurement_date, measurement_time, measurement_type, measured_value, measurement_unit, test_conditions.

**Identity fields:** measurement_type, measurement_date.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

# 12 · Finance public administration and law

## BNK — Banking lending and financial services (3 templates)

Shared category context: institution_ref, case_or_account_alias, product_ref.

### BNK-005 — Loan application

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** bnk_loan_application_intake.

**Fields only:** request_reference, request_date, requester_name, requested_amount, requested_currency, loan_purpose, repayment_evidence.

**Identity fields:** request_reference.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### BNK-014 — Loan repayment

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** bnk_loan_repayment_record.

**Fields only:** loan_reference, transaction_reference, payment_date, payment_amount, payment_currency, source_documents.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### BNK-018 — Savings contribution

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** bnk_savings_contribution_record.

**Fields only:** member_reference, meeting_date, contribution_amount, contribution_currency, transaction_reference.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## INS — Insurance claims and loss assessment (3 templates)

Shared category context: insurer_or_broker_ref, policy_alias, claim_or_survey_ref.

### INS-003 — Insurance policy

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** ins_insurance_policy_extraction.

**Fields only:** policy_number, insurer_or_broker_ref, effective_date, policy_terms, source_reference.

**Identity fields:** policy_number.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### INS-007 — Property risk inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** ins_property_risk_survey.

**Fields only:** inspection_scope, inspection_date, building_features, observed_hazards, survey_limitations, recommended_actions.

**Identity fields:** inspection_scope.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### INS-009 — Insurance claim

**Type:** Case-management workflow · **Shared pack:** CASE.

**Stable key:** ins_insurance_claim_notification.

**Fields only:** case_reference, case_opened_date, policy_reference, reported_event, initial_evidence, case_stage.

**Identity fields:** case_reference.

**Capture:** Forms; documents; consented media; messages.

**AI assistance:** Summarize supplied evidence; extract dates; suggest routing; redact selected copies.

**Potential outputs:** Case file; chronology; action list; closure report.

**Review:** Authorized handler; restricted access; no automated adverse decision.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## GOV — Government municipal and citizen services (3 templates)

Shared category context: authority_ref, service_area, application_or_case_ref.

### GOV-001 — Citizen service request

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** gov_citizen_service_request.

**Fields only:** request_reference, request_date, service_type, request_details, preferred_contact, decision.

**Identity fields:** request_reference.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### GOV-004 — Business licence application

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** gov_business_license_application_intake.

**Fields only:** request_reference, request_date, business_details, requested_activity, supporting_documents, decision.

**Identity fields:** request_reference.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### GOV-010 — Public service fee receipt

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** gov_municipal_fee_payment_record.

**Fields only:** service_reference, transaction_date, counterparty_name, approved_fee, approved_fee_currency, receipt_reference.

**Identity fields:** service_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## JUS — Justice legal aid and public safety administration (3 templates)

Shared category context: authorized_organization_ref, case_ref, restricted_jurisdiction.

### JUS-001 — Legal aid intake

**Type:** Case-management workflow · **Shared pack:** CASE.

**Stable key:** jus_legal_aid_client_intake.

**Fields only:** case_reference, case_opened_date, client_stated_issue, service_eligibility_evidence, consent, assigned_handler_name.

**Identity fields:** case_reference.

**Capture:** Forms; documents; consented media; messages.

**AI assistance:** Summarize supplied evidence; extract dates; suggest routing; redact selected copies.

**Potential outputs:** Case file; chronology; action list; closure report.

**Review:** Authorized handler; restricted access; no automated adverse decision.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### JUS-004 — Court document register

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** jus_court_document_intake_index.

**Fields only:** document_reference, record_subject, filing_date, verified_case_link, source_reference.

**Identity fields:** document_reference.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### JUS-013 — Evidence custody receipt

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** jus_evidence_receipt_and_custody.

**Fields only:** evidence_identifier, transaction_date, counterparty_name, authorized_transfer, integrity_record, case_ref.

**Identity fields:** evidence_identifier.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

# 13 · Risk resilience and sustainability

## ENV — Environment climate and sustainability (3 templates)

Shared category context: organization_or_program_ref, site_ref, monitoring_period.

### ENV-004 — Environmental site inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** env_environmental_site_inspection.

**Fields only:** inspection_date, site_ref, observed_condition, inspection_result, defects, recommended_actions.

**Identity fields:** site_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### ENV-005 — Air quality reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** env_air_quality_monitoring.

**Fields only:** measurement_type, measured_value, measurement_unit, measurement_date, measurement_time, monitoring_location, instrument_ref.

**Identity fields:** measurement_type, measurement_date.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### ENV-010 — Spill report

**Type:** Incident workflow · **Shared pack:** INCIDENT.

**Stable key:** env_environmental_spill_observation.

**Fields only:** event_date, event_time, event_location, observed_material, visible_extent, immediate_action, factual_description.

**Identity fields:** event_location, event_date, event_time.

**Capture:** Photos; explicit audio notes; manual observations; documents.

**AI assistance:** Transcribe reports; build timeline; separate observations from allegations and inferred causes.

**Potential outputs:** Incident report; evidence log; response actions; follow-up record.

**Review:** Qualified review for high-impact incidents; do not infer blame.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## EMR — Emergencies disasters and humanitarian response (3 templates)

Shared category context: response_organization_ref, incident_ref, affected_area.

### EMR-001 — Incident report

**Type:** Incident workflow · **Shared pack:** INCIDENT.

**Stable key:** emr_emergency_incident_intake.

**Fields only:** event_date, event_time, event_location, event_type, factual_description, people_affected_count, immediate_action.

**Identity fields:** event_location, event_date, event_time.

**Capture:** Photos; explicit audio notes; manual observations; documents.

**AI assistance:** Transcribe reports; build timeline; separate observations from allegations and inferred causes.

**Potential outputs:** Incident report; evidence log; response actions; follow-up record.

**Review:** Qualified review for high-impact incidents; do not infer blame.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### EMR-002 — Emergency needs assessment

**Type:** Survey / questionnaire · **Shared pack:** SURVEY.

**Stable key:** emr_rapid_needs_assessment.

**Fields only:** respondent_or_sample_code, interview_date, consent_status, priority_needs, sampling_scope, data_limitations, interviewer_notes.

**Identity fields:** respondent_or_sample_code.

**Capture:** Manual interviews; self-completion; consented audio; optional GPS.

**AI assistance:** Transcribe responses; classify open answers for review; summarize aggregate data.

**Potential outputs:** Response dataset; survey summary; coded response table.

**Review:** Preserve consent and sampling limits; do not infer sensitive traits.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### EMR-009 — Relief item distribution

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** emr_relief_distribution_verification.

**Fields only:** transaction_reference, transaction_date, recipient_code, item_name, quantity_total, quantity_unit, acknowledgement.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## FIR — Fire safety security and facilities protection (2 templates)

Shared category context: organization_ref, facility_ref, inspection_or_event_ref.

### FIR-002 — Fire extinguisher inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** fir_fire_extinguisher_inspection.

**Fields only:** inspection_date, facility_ref, visible_condition, service_status, inspection_result, recommended_actions.

**Identity fields:** facility_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### FIR-022 — Security patrol visit

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** fir_security_patrol_checkpoint_record.

**Fields only:** activity_date, visit_time, authorized_checkpoint, observed_conditions, outcome.

**Identity fields:** authorized_checkpoint, activity_date, visit_time.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## OSH — Occupational safety quality and wellbeing (2 templates)

Shared category context: organization_ref, worksite_ref, activity_or_case_ref.

### OSH-001 — Workplace hazard

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Stable key:** osh_workplace_hazard_observation.

**Fields only:** observed_at, observed_hazard, work_location, immediate_action, observer_name.

**Identity fields:** work_location, observed_at.

**Capture:** Photos; explicit audio captions; video; optional GPS and time.

**AI assistance:** OCR or transcribe visible evidence; propose tags and captions; retain source links.

**Potential outputs:** Observation record; photo sheet; annotated evidence bundle.

**Review:** Observed, reported and inferred details must remain distinguishable.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### OSH-007 — Protective equipment issue

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** osh_personal_protective_equipment_issue.

**Fields only:** issue_date, equipment_item, recipient_reference, quantity_total, quantity_unit.

**Identity fields:** recipient_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

# 14 · Social impact culture and information

## NPO — Nonprofits volunteers and community organizations (2 templates)

Shared category context: organization_ref, program_ref, community_or_partner_ref.

### NPO-005 — Community service delivery

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** npo_beneficiary_service_record.

**Fields only:** transaction_date, participant_code, delivered_service, verification, program_ref.

**Identity fields:** participant_code.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### NPO-023 — Goods donation

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** npo_charitable_goods_donation_intake.

**Fields only:** transaction_date, donor_reference, item_name, quantity_total, quantity_unit, usage_restrictions.

**Identity fields:** donor_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## DEV — Development surveys and monitoring evaluation (3 templates)

Shared category context: program_ref, survey_or_indicator_ref, geographic_scope.

### DEV-001 — Household survey

**Type:** Survey / questionnaire · **Shared pack:** SURVEY.

**Stable key:** dev_household_socioeconomic_survey.

**Fields only:** consented_household_code, interview_date, consent_status, household_size, household_income_amount, household_income_currency, interviewer_notes.

**Identity fields:** consented_household_code.

**Capture:** Manual interviews; self-completion; consented audio; optional GPS.

**AI assistance:** Transcribe responses; classify open answers for review; summarize aggregate data.

**Potential outputs:** Response dataset; survey summary; coded response table.

**Review:** Preserve consent and sampling limits; do not infer sensitive traits.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### DEV-004 — Program indicator reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** dev_indicator_measurement_submission.

**Fields only:** indicator_reference, measured_value, measurement_unit, measurement_date, reporting_period, method_reference.

**Identity fields:** indicator_reference, measurement_date.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### DEV-021 — Interview record

**Type:** Meeting / collaboration · **Shared pack:** MEET.

**Stable key:** dev_key_informant_interview.

**Fields only:** meeting_title, meeting_date, informant_role, consent, verified_statements.

**Identity fields:** meeting_title, meeting_date.

**Capture:** Manual notes; explicitly consented audio; uploaded files.

**AI assistance:** Transcribe; propose speaker labels; summarize; extract candidate decisions and action owners.

**Potential outputs:** Minutes draft; attendance register; action tracker; follow-up draft.

**Review:** Participants or chair confirm decisions and attributions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## MED — Media journalism publishing and content (2 templates)

Shared category context: organization_ref, story_or_production_ref, publication_channel.

### MED-003 — Reporter field notes

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** med_reporter_field_notebook.

**Fields only:** activity_date, activity_type, firsthand_observations, source_references, verification_needs.

**Identity fields:** activity_date, activity_type.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### MED-008 — Fact check

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** med_fact_check_worksheet.

**Fields only:** check_date, claim, source_evidence, verification_outcome, reviewer_name.

**Identity fields:** reviewer_name.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## ART — Arts heritage museums and libraries (3 templates)

Shared category context: institution_or_collection_ref, object_or_program_ref, location_ref.

### ART-001 — Collection item

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** art_museum_object_accession.

**Fields only:** accession_number, object_name, category, location_ref, condition_grade, provenance_evidence.

**Identity fields:** accession_number.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### ART-002 — Collection condition report

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** art_museum_object_condition_report.

**Fields only:** object_reference, inspection_date, condition_grade, observed_condition, defects, recommended_actions, inspector_name.

**Identity fields:** object_reference.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### ART-028 — Library loan

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** art_library_lending_transaction.

**Fields only:** transaction_reference, transaction_date, item_reference, borrower_alias, return_date.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

# 15 · Commerce hospitality and recreation

## RET — Retail wholesale and e-commerce (3 templates)

Shared category context: business_ref, store_or_channel_ref, product_or_order_ref.

### RET-001 — Retail product

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** ret_retail_product_listing.

**Fields only:** stock_code, product_name, category, verified_specifications, unit_price, unit_price_currency, entry_status.

**Identity fields:** stock_code.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### RET-007 — Retail sale

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** ret_retail_sales_transaction.

**Fields only:** transaction_reference, transaction_date, sold_items, total_amount, total_currency, payment_reference.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### RET-017 — Product return

**Type:** Case-management workflow · **Shared pack:** CASE.

**Stable key:** ret_product_return_intake.

**Fields only:** case_reference, case_opened_date, original_order, return_reason, item_condition, case_stage, followup_actions.

**Identity fields:** case_reference.

**Capture:** Forms; documents; consented media; messages.

**AI assistance:** Summarize supplied evidence; extract dates; suggest routing; redact selected copies.

**Potential outputs:** Case file; chronology; action list; closure report.

**Review:** Authorized handler; restricted access; no automated adverse decision.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

## HOS — Hotels restaurants catering and accommodation (3 templates)

Shared category context: business_ref, property_or_outlet_ref, booking_or_service_ref.

### HOS-001 — Guest reservation

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** hos_guest_reservation_intake.

**Fields only:** request_reference, requester_name, phone_primary, arrival_date, departure_date, room_preferences, decision.

**Identity fields:** request_reference.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### HOS-005 — Room housekeeping

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** hos_room_housekeeping_checklist.

**Fields only:** check_date, property_or_outlet_ref, cleaning_tasks, linen_status, maintenance_findings, overall_result.

**Identity fields:** property_or_outlet_ref.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### HOS-020 — Restaurant order item

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** hos_restaurant_food_order.

**Fields only:** transaction_reference, transaction_date, menu_item, quantity_counted, customer_stated_requirements, total_amount, total_currency.

**Identity fields:** transaction_reference.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

## TOU — Travel tourism recreation and visitor services (2 templates)

Shared category context: operator_ref, trip_or_experience_ref, destination_scope.

### TOU-002 — Travel itinerary

**Type:** Plan / schedule · **Shared pack:** PLAN.

**Stable key:** tou_travel_itinerary_planning.

**Fields only:** plan_title, start_date, end_date, destination_scope, daily_schedule, confirmed_services.

**Identity fields:** plan_title.

**Capture:** Manual entry; existing records; requirement documents.

**AI assistance:** Organize activities; draft a sequence; surface dependencies and missing assumptions.

**Potential outputs:** Plan; schedule; assignment table; planning brief.

**Review:** Owner confirms dates, resources and assumptions.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

### TOU-004 — Tour booking

**Type:** Generated document · **Shared pack:** DOC.

**Stable key:** tou_tour_booking_confirmation.

**Fields only:** document_reference, traveler_name, start_date, end_date, confirmed_itinerary, traveler_requirements, agreed_terms.

**Identity fields:** document_reference.

**Capture:** Documents; source records; approved brand assets.

**AI assistance:** Build required structure; draft source-linked content; flag missing inputs.

**Potential outputs:** Document draft; PDF or DOCX export; evidence index.

**Review:** Review all facts, professional conclusions, formatting and signatures.

**Default privacy:** Confidential · **Rollout:** P1 · Expansion.

## SPO — Sports fitness and recreation organizations (3 templates)

Shared category context: organization_ref, team_or_program_ref, event_or_session_ref.

### SPO-002 — Athlete registration

**Type:** Profile / intake · **Shared pack:** PROFILE.

**Stable key:** spo_athlete_registration.

**Fields only:** athlete_reference, display_name, team_assignment, phone_primary, email_address, consent_status, guardian_authority_when_needed.

**Identity fields:** display_name.

**Capture:** Manual entry; approved documents; contact imports.

**AI assistance:** Extract supplied profile data; flag conflicts; reuse only approved facts.

**Potential outputs:** Profile card; directory entry; intake summary.

**Review:** Collect only necessary personal data; obtain required permissions.

**Default privacy:** Restricted · **Rollout:** P1 · Expansion.

### SPO-005 — Training attendance

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** spo_training_attendance_record.

**Fields only:** effective_date, session_reference, participant_code, attendance, team_or_program_ref.

**Identity fields:** session_reference.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Restricted · **Rollout:** P1 · Expansion.

### SPO-014 — Match result

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** spo_match_result_verification.

**Fields only:** event_or_session_ref, check_date, home_team, away_team, home_score, away_score, official_result_source, authorized_confirmation.

**Identity fields:** event_or_session_ref.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Restricted · **Rollout:** P1 · Expansion.

# 16 · Professional specialist and personal services

## PRO — Consulting professional and business services (1 templates)

Shared category context: service_firm_ref, client_ref, engagement_ref.

### PRO-003 — Professional service brief

**Type:** Generated document · **Shared pack:** DOC.

**Stable key:** pro_professional_services_engagement_brief.

**Fields only:** document_reference, document_title, client_ref, agreed_scope, deliverables, commercial_terms.

**Identity fields:** document_reference.

**Capture:** Documents; source records; approved brand assets.

**AI assistance:** Build required structure; draft source-linked content; flag missing inputs.

**Potential outputs:** Document draft; PDF or DOCX export; evidence index.

**Review:** Review all facts, professional conclusions, formatting and signatures.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## FAC — Facilities cleaning repairs and local services (1 templates)

Shared category context: service_provider_ref, customer_or_site_ref, job_ref.

### FAC-004 — Cleaning checklist

**Type:** Checklist / verification · **Shared pack:** CHECK.

**Stable key:** fac_cleaning_task_checklist.

**Fields only:** check_date, customer_or_site_ref, assigned_zones, required_tasks, overall_result, exceptions.

**Identity fields:** customer_or_site_ref.

**Capture:** Manual checks; photos; documents; instrument readings.

**AI assistance:** Read supporting evidence; suggest item matches; highlight missing evidence.

**Potential outputs:** Completed checklist; exception list; verification report.

**Review:** Each pass or fail must have evidence or a documented reviewer basis.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## PER — Personal household family and everyday records (2 templates)

Shared category context: owner_ref, household_or_personal_project_ref, privacy_scope.

### PER-015 — Personal appointment

**Type:** Tracker / follow-up · **Shared pack:** TRACK.

**Stable key:** per_personal_appointment_tracker.

**Fields only:** tracked_item, appointment_type, target_date, scheduled_time, current_stage.

**Identity fields:** tracked_item.

**Capture:** Linked records; manual updates; imported events.

**AI assistance:** Extract dates and commitments; propose status updates with evidence.

**Potential outputs:** Tracker; overdue list; follow-up draft; completion report.

**Review:** Status changes must be confirmed or tied to a trusted event.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### PER-028 — Borrowed item

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** per_borrowed_belongings_register.

**Fields only:** item_reference, borrower, effective_date, return_due_date, entry_status.

**Identity fields:** item_reference.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## FAI — Faith communities ceremonies and associations (2 templates)

Shared category context: organization_ref, program_or_event_ref, voluntary_participant_ref.

### FAI-001 — Community member registration

**Type:** Profile / intake · **Shared pack:** PROFILE.

**Stable key:** fai_faith_community_voluntary_registration.

**Fields only:** profile_reference, display_name, phone_primary, email_address, participation_preferences, explicit_consent, consent_date.

**Identity fields:** profile_reference, display_name.

**Capture:** Manual entry; approved documents; contact imports.

**AI assistance:** Extract supplied profile data; flag conflicts; reuse only approved facts.

**Potential outputs:** Profile card; directory entry; intake summary.

**Review:** Collect only necessary personal data; obtain required permissions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### FAI-016 — Ceremony booking

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** fai_ceremony_booking_request.

**Fields only:** request_reference, requester_name, ceremony_type, preferred_date, organizer_contact, decision.

**Identity fields:** request_reference.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## LIF — Beauty wellbeing ceremonies and end-of-life services (3 templates)

Shared category context: provider_ref, consented_client_ref, service_ref.

### LIF-003 — Beauty service record

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** lif_salon_service_record.

**Fields only:** activity_date, consented_client_ref, agreed_service, products_used, participants_or_operators, client_feedback.

**Identity fields:** consented_client_ref, activity_date.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### LIF-021 — Funeral service request

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** lif_funeral_service_request.

**Fields only:** request_reference, request_date, family_authorized_contact, requested_services, required_by_date, official_document_checklist.

**Identity fields:** request_reference.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### LIF-024 — Cemetery plot

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** lif_cemetery_plot_register.

**Fields only:** plot_identifier, record_subject, effective_date, authorized_rights_record, restricted_contact.

**Identity fields:** plot_identifier.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

# 17 · Specialist and emerging domains

## SCI — Space astronomy earth and physical sciences (1 templates)

Shared category context: research_or_operator_ref, instrument_or_site_ref, campaign_ref.

### SCI-001 — Astronomy observation

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** sci_astronomy_observation_log.

**Fields only:** activity_date, target_identifier, observation_time, instrument_or_site_ref, instrument_configuration, observations, outcome.

**Identity fields:** target_identifier, activity_date, observation_time.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

## ACC — Accessibility inclusion and equitable services (3 templates)

Shared category context: organization_ref, service_or_site_ref, assessment_ref.

### ACC-002 — Physical access inspection

**Type:** Inspection / field form · **Shared pack:** INSPECT.

**Stable key:** acc_building_access_route_inspection.

**Fields only:** inspection_date, service_or_site_ref, route_features, measured_length_mm, measured_width_mm, measured_height_mm, observed_barriers.

**Identity fields:** service_or_site_ref.

**Capture:** Photos; manual entry; measurements; optional GPS.

**AI assistance:** Extract labels; organize photo observations; draft findings for inspector confirmation.

**Potential outputs:** Inspection checklist; condition report; defect schedule; work requests.

**Review:** Inspector validates findings; a photo alone is not certification.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### ACC-007 — Digital accessibility issue

**Type:** Register / master data · **Shared pack:** REG.

**Stable key:** acc_website_accessibility_findings.

**Fields only:** effective_date, page_reference, observed_issue, test_evidence, entry_status.

**Identity fields:** page_reference.

**Capture:** Manual entry; documents; media; structured imports.

**AI assistance:** Extract and normalize entries; detect possible duplicates; flag conflicting sources.

**Potential outputs:** Searchable register; record card; spreadsheet export.

**Review:** Verify authoritative source and permission to store data.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### ACC-017 — Workplace adjustment

**Type:** Tracker / follow-up · **Shared pack:** TRACK.

**Stable key:** acc_workplace_adjustment_tracking.

**Fields only:** tracked_item, agreed_adjustment, responsible_owner, target_date, current_stage, review_date.

**Identity fields:** tracked_item.

**Capture:** Linked records; manual updates; imported events.

**AI assistance:** Extract dates and commitments; propose status updates with evidence.

**Potential outputs:** Tracker; overdue list; follow-up draft; completion report.

**Review:** Status changes must be confirmed or tied to a trusted event.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## ELE — Elections civic participation and associations (3 templates)

Shared category context: authorized_body_ref, event_ref, administrative_area.

### ELE-010 — Election observation

**Type:** Observation / evidence capture · **Shared pack:** OBS.

**Stable key:** ele_nonpartisan_election_observation.

**Fields only:** observation_subject, observed_at, administrative_area, firsthand_facts, evidence, observer_name.

**Identity fields:** observation_subject, observed_at.

**Capture:** Photos; explicit audio captions; video; optional GPS and time.

**AI assistance:** OCR or transcribe visible evidence; propose tags and captions; retain source links.

**Potential outputs:** Observation record; photo sheet; annotated evidence bundle.

**Review:** Observed, reported and inferred details must remain distinguishable.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### ELE-012 — Election result entry

**Type:** Transaction / repeated line items · **Shared pack:** TRANS.

**Stable key:** ele_official_results_form_capture.

**Fields only:** event_ref, administrative_area, source_form, candidate_name, vote_count, transaction_date, double_verification.

**Identity fields:** event_ref.

**Capture:** Invoice or receipt photos; documents; barcode; manual entry.

**AI assistance:** Extract header and line items; preserve units; reconcile computed and printed totals.

**Potential outputs:** Transaction table; line-item export; reconciliation sheet; receipt or voucher draft.

**Review:** Verify quantities, identifiers and monetary totals before posting.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

### ELE-016 — Election material handover

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** ele_ballot_material_custody_record.

**Fields only:** activity_date, start_time, sealed_container, authorized_transfer, custody_confirmation, participants_or_operators.

**Identity fields:** sealed_container, activity_date, start_time.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## DEF — Defense peacekeeping and veteran administration (1 templates)

Shared category context: authorized_organization_ref, program_ref, administrative_case_ref.

### DEF-010 — Veteran benefit request

**Type:** Request / approval workflow · **Shared pack:** REQUEST.

**Stable key:** def_veteran_benefit_application_intake.

**Fields only:** request_reference, requester_name, request_date, request_purpose, published_eligibility, supporting_evidence, consent.

**Identity fields:** request_reference.

**Capture:** Manual entry; documents; photos; existing records.

**AI assistance:** Structure the request; extract supporting facts; flag missing information.

**Potential outputs:** Request form; approval record; notification draft.

**Review:** Authorization required before payments, submissions or external actions.

**Default privacy:** Restricted · **Rollout:** P2 · Specialist.

## ADV — Electronics advanced fabrication and industrial R&D (3 templates)

Shared category context: facility_ref, product_or_experiment_ref, batch_or_serial_ref.

### ADV-001 — Electronic component

**Type:** Register / master data · **Shared pack:** ASSET.

**Stable key:** adv_electronic_component_catalogue.

**Fields only:** part_number, item_name, manufacturer_name, approved_specification, quantity_counted.

**Identity fields:** part_number.

**Capture:** Label photos; barcode or QR; manual entry; existing registers.

**AI assistance:** OCR visible labels; propose normalized fields; flag duplicates and unreadable values.

**Potential outputs:** Asset register; asset card; inventory export; label sheet.

**Review:** Verify identifiers against source; never infer serial numbers from appearance.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### ADV-006 — Electronics test reading

**Type:** Measurement / calculation · **Shared pack:** MEASURE.

**Stable key:** adv_functional_electronics_test_record.

**Fields only:** measurement_type, measured_value, measurement_unit, measurement_date, batch_or_serial_ref, approved_test_plan, quality_decision.

**Identity fields:** measurement_type, measurement_date.

**Capture:** Manual instruments; device integrations; visible meter photos; optional GPS and capture time.

**AI assistance:** OCR visible readings; normalize approved units; flag implausible values without changing raw readings.

**Potential outputs:** Measurement log; trend dataset; reviewed calculation worksheet.

**Review:** Verify units, calibration and method; no safety threshold inferred by AI.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.

### ADV-020 — 3D print build

**Type:** Activity / event log · **Shared pack:** LOG.

**Stable key:** adv_3d_print_build_record.

**Fields only:** activity_date, product_or_experiment_ref, design_revision, material_lot, approved_build_profile, outcome.

**Identity fields:** product_or_experiment_ref, activity_date.

**Capture:** Manual entry; time capture; media; instrument feeds.

**AI assistance:** Transcribe notes; order events; flag inconsistent chronology.

**Potential outputs:** Activity log; timeline; period summary.

**Review:** Preserve original events and corrections; distinguish device and server times.

**Default privacy:** Confidential · **Rollout:** P2 · Specialist.
