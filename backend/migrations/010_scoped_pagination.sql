-- Bound read work to the requested account, project and cursor position.
BEGIN;

-- Organisation user pages order by identifier after filtering the organisation.
CREATE INDEX users_org_page_idx ON users (organisation_id, id);

-- Visible project pages order by identifier within an organisation.
CREATE INDEX projects_org_page_idx ON projects (organisation_id, id);

-- Device pages and relay acknowledgement participants filter by account.
CREATE INDEX devices_user_page_idx ON devices (user_id, id);

-- Relay inbox pages resume from their timestamp/identifier keyset position.
CREATE INDEX relay_packages_project_page_idx ON relay_packages (project_id, created_at, id);

-- Actor-scoped usage pages inside a project never copy the deployment history.
CREATE INDEX ai_usage_actor_page_idx ON ai_usage (project_id, user_id, id);

-- Composite page indexes also serve these older single-column lookups.
DROP INDEX projects_org_idx;
DROP INDEX devices_user_idx;
DROP INDEX relay_packages_project_idx;

COMMIT;
