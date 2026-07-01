# SocialHub Custom Admin Panel Implementation Plan

Research date: 2026-07-01

## 1. Goal

SocialHub ke liye ek custom, private Admin Panel banana hai jo existing
Next.js, Tailwind CSS, Clerk, FastAPI, SQLAlchemy, PostgreSQL, and AWS stack
ke saath integrate ho.

The selected implementation is:

```text
Custom Next.js Admin
  + Existing Next.js and Tailwind design system
  + Clerk role-based access control
  + FastAPI admin-only endpoints
  + AWS Secrets Manager for API keys
  + AWS SSM Parameter Store for active model configuration
```

The Admin Panel will:

- Be visible only to authorized administrators.
- Initially be accessible only by the product owner.
- Allow the owner to invite or promote additional admins.
- Show a paginated list of signed-up users.
- Show per-user published, pending, failed, and cancelled post statistics.
- Show connected social platforms and recent activity for a selected user.
- Show every registered Main/hidden agent and its active model.
- Allow a super admin to change an agent's model safely.
- Show compatible free and paid GLM models in grouped dropdowns.
- Allow secure API-key selection, addition, rotation, and rollback.
- Never expose raw API keys to the browser.
- Provide a direct switch between Admin Panel and normal Main Agent UI.

System-wide LLM rule:

- SocialHub has exactly one LLM gateway: the Z.AI GLM gateway.
- OpenRouter gateway code and configuration will be removed.
- The Admin Panel cannot select OpenRouter or non-GLM providers/models.
- Runtime models, limits, thinking settings, and catalogs are loaded from AWS
  configuration and are not hardcoded in agent code.

## 2. Research Summary

Admin systems such as Stripe and Shopify use the same core security pattern:

- Owner/admin roles.
- Invitation-based access.
- Least-privilege permissions.
- MFA or 2FA for privileged users.
- Role management and immediate access revocation.
- Security/audit history for sensitive actions.

Open-source research considered:

| Option | Finding |
|---|---|
| Custom Next.js Admin | Best fit for SocialHub's existing Next.js/Tailwind UI |
| Refine | Strong React admin framework, but adds an additional UI/data framework |
| React Admin | Mature CRUD framework, but primarily Material UI based |
| SQLAdmin | Good FastAPI/SQLAlchemy backend admin, but visually separate from SocialHub |

Decision:

```text
Build a custom Next.js Admin Panel.
```

Reasons:

- Same design language as `/agent`.
- Reuses existing Clerk authentication.
- No separate admin application to deploy.
- Minimum dependency and maintenance overhead.
- Full control over sensitive API-key and model-management workflows.
- Better fit for user-detail drawers and agent/model controls than generic CRUD.

## 3. Roles and Permissions

### 3.1 Roles

| Role | Access |
|---|---|
| `super_admin` | Full access, admin management, API keys, agent models |
| `admin` | User analytics and operational read-only access |
| `support_admin` | Optional future role with limited user/status access |
| Normal user | No Admin Panel access |

Initial setup:

- Product owner is manually assigned `super_admin` through Clerk.
- No other user has admin access.
- Only `super_admin` can add, remove, or change admin roles.
- An `admin` cannot promote itself to `super_admin`.
- A `super_admin` cannot remove the last remaining `super_admin`.

### 3.2 Clerk Integration

For the initial small admin team, use Clerk metadata RBAC:

```json
{
  "role": "super_admin"
}
```

The role is included in Clerk session claims.

Authorization must be enforced at both levels:

```text
Frontend:
  Protect /admin and hide Admin Panel navigation.

Backend:
  Verify Clerk JWT and require admin/super_admin for every /admin API.
```

Hiding the button or route is not security. Backend authorization is mandatory.

When a role is revoked:

- Revoke or refresh the user's Clerk sessions.
- Reject existing stale sessions at the backend where practical.
- Record the role change in the audit log.

### 3.3 Adding Another Admin

Existing SocialHub user:

1. Super admin searches the user.
2. Selects `Grant admin access`.
3. Reviews the requested role.
4. Confirms.
5. Backend uses Clerk Backend API to update metadata.
6. Audit event is recorded.

New person:

1. Super admin enters an email address.
2. Backend creates a Clerk invitation.
3. Invitation contains approved role metadata.
4. User accepts the invitation and signs in.
5. Backend verifies the resulting role before allowing `/admin`.

Admin accounts should be required to use MFA/2FA where supported by the active
Clerk plan.

## 4. Navigation Between Admin and User UI

Admin Panel:

```text
/admin
  -> top-right "Open User App"
  -> /agent
```

Normal Main Agent UI:

```text
/agent
  -> profile menu
  -> "Admin Panel"
  -> /admin
```

Rules:

- `Admin Panel` is shown only when the current session has an admin role.
- `Open User App` is shown to all authorized admins.
- Both use the same Clerk session.
- No logout or second login is required.
- Direct navigation to `/admin` still performs a server-side role check.
- A normal user receives a safe redirect or 404/403 response.

## 5. Admin Panel Information Architecture

```text
/admin
├── Overview
├── Users
├── Agents & Models
├── API Keys
├── Admin Access
└── Audit Log
```

### 5.1 Overview

Summary cards:

- Total users.
- New users in the last 7/30 days.
- Total published posts.
- Total pending posts.
- Total failed posts.
- Active connected platforms.
- Agent provider health.
- Recent critical failures.

Overview cards must use aggregate backend queries, not client-side counting.

### 5.2 Users

Default view:

- Paginated/virtualized sequence of users.
- Name.
- Primary email.
- Signup date.
- Last login/last activity where available.
- Account status.
- Search by name or email.
- Sort by name, signup date, or recent activity.

The initial list must not load detailed statistics for every user individually.
That would cause an N+1 query problem.

When an admin clicks a user's name, open a detail drawer/page and fetch:

- User name and email.
- Clerk user ID and internal user ID where useful for support.
- Signup date and last activity.
- Published posts.
- Pending posts.
- Failed posts.
- Cancelled posts.
- Connected Facebook Pages.
- Connected Instagram account.
- Connected LinkedIn account.
- Connected X account.
- Recent scheduled/published/failed posts.
- Failure reason for failed posts.

Post status mapping from the current schema:

| Admin metric | `scheduled_posts.status` |
|---|---|
| Published | `published` |
| Pending | `pending` |
| Failed | `failed` |
| Cancelled | `cancelled` |

All user-level queries must filter by `ScheduledPost.user_id`.

### 5.3 Agents & Models

This section is visible only to `super_admin`.

The UI must show:

- Total number of registered agents.
- One visible Main Agent.
- All hidden agents used in the backend.
- Agent display name.
- Internal agent key.
- Visibility: `User-visible` or `Hidden`.
- Current provider.
- Current model.
- Model pricing type: `Free` or `Paid`.
- Thinking mode.
- Maximum output tokens.
- Last successful call.
- Last failure.
- Recent p50/p95 latency.
- Recent token usage.
- Health state.

Example:

| Agent | Visibility | Active model | Tier |
|---|---|---|---|
| Main Agent | User-visible | GLM-5.2 | Paid |
| Connection Agent | Hidden | GLM-4.7-FlashX | Paid |
| Copywriting Agent | Hidden | GLM-4.7 | Paid |
| Safety Review Agent | Hidden | GLM-4.7 | Paid |

Important:

- Agent count must not be hardcoded as 11, 13, or any fixed value.
- Backend must enumerate `AGENT_REGISTRY`.
- Add virtual entries for `main` and `main_final` where they are separate model
  roles.
- New agents automatically appear when registered.
- Normal users must never receive this registry/model information.
- All model changes continue to use the same single Z.AI gateway.
- The UI must not offer a provider selector because only Z.AI is approved.

### 5.4 GLM Model Dropdown

Each text agent gets a model dropdown grouped by:

```text
Recommended
Free
Paid
Experimental
Unavailable for current API key
```

Initial approved text-model catalog:

| Model | Tier | Notes |
|---|---|---|
| `glm-5.2` | Paid/experimental until General API verified | Main/long-horizon tasks |
| `glm-5.1` | Paid | Strong flagship |
| `glm-5` | Paid | Complex agentic work |
| `glm-5-turbo` | Paid | Long-running agent work |
| `glm-4.7` | Paid | Complex SocialHub agents |
| `glm-4.7-flashx` | Paid | Cheap, fast production agents |
| `glm-4.7-flash` | Free | Controlled testing |
| `glm-4.6` | Paid | General fallback |
| `glm-4.5` | Paid | Reasoning/tool work |
| `glm-4.5-air` | Paid | Cost-effective |
| `glm-4.5-x` | Paid | Fast premium variant |
| `glm-4.5-airx` | Paid | Fast lightweight variant |
| `glm-4.5-flash` | Free | Testing/fallback |
| `glm-4-32b-0414-128k` | Paid | Low-cost text fallback |

Image Generation Agent gets a compatible image-model dropdown:

| Model | Tier |
|---|---|
| `glm-image` | Paid |
| `cogview-4-250304` | Paid |

Professional compatibility rule:

- Text agents only see text models.
- Image generation only sees image models.
- Future vision agents only see vision-capable models.
- An incompatible model cannot be selected even by manually editing the request.

Z.AI documentation does not currently expose a dependable public "list all
models" endpoint for this use case. Therefore:

- Maintain an approved model catalog in AWS SSM Parameter Store, not as a
  hardcoded Python/TypeScript list.
- Store model ID, modality, free/paid tier, context limit, and status.
- Review the catalog against official Z.AI documentation periodically.
- Run a live capability probe before activating a model.
- Mark undocumented models such as direct General API `glm-5.2` as experimental
  until the key successfully calls them.

### 5.5 Safe Model Change Workflow

Changing a model must not take effect immediately from an unvalidated dropdown.

Flow:

1. Super admin opens an agent.
2. Selects a compatible GLM model.
3. UI shows free/paid status and expected cost impact.
4. Admin clicks `Test model`.
5. Backend performs a safe, non-mutating capability probe:
   - Authentication.
   - Model availability.
   - Text response.
   - JSON mode where required.
   - Tool/structured-output capability where required.
   - Latency.
6. Backend validates the response with the agent's contract.
7. UI shows pass/fail and warnings.
8. Admin confirms `Activate model`.
9. Backend writes a new version of the model map.
10. Gateway invalidates its configuration cache.
11. A smoke test runs.
12. On success, configuration remains active.
13. On failure, automatically restore the previous version.
14. Record the complete action in the audit log.

Additional controls:

- `Reset to recommended`.
- `Rollback to previous`.
- Optional scheduled activation.
- Prevent changing an agent while a risky mutation is actively executing.
- Existing workflows retain their recorded model metadata.
- New commands use the new model.
- User memory is not deleted or changed.

## 6. AWS API-Key Management

### 6.1 Source of Truth

Current `.env`-only behavior does not support automatic runtime key changes.

Target:

```text
AWS Secrets Manager
  -> stores API-key values

AWS SSM Parameter Store
  -> stores active key alias and agent-model mapping

Backend provider gateway
  -> reads the active configuration securely
```

Separation:

| Data | Storage |
|---|---|
| Raw API key | AWS Secrets Manager |
| Active key alias/Secret ARN | AWS SSM Parameter Store |
| Agent-to-model map | AWS SSM Parameter Store |
| Approved GLM model catalog | AWS SSM Parameter Store |
| Thinking/token limits | AWS SSM Parameter Store |
| User/admin role | Clerk |
| User/post statistics | PostgreSQL |
| Audit events | Structured backend logs initially; DB table later if approved |

### 6.2 No Direct AWS Access From Browser

The Admin Panel must never:

- Receive AWS credentials.
- Call AWS Secrets Manager directly.
- Receive an existing raw API key.
- Display full API-key values.
- Store keys in local storage, Redux, cookies, or browser logs.

Required path:

```text
Admin browser
  -> Clerk-authenticated admin API
  -> FastAPI super_admin authorization
  -> Restricted backend AWS SDK/client
  -> AWS Secrets Manager/SSM
```

### 6.3 API-Key Screen

Show:

- Friendly alias such as `Z.AI Primary`.
- Provider.
- Status: active/inactive/failed.
- Created/updated date.
- Last validation date.
- Last four characters only where securely available.
- Recent success/failure health.

Actions:

- Add a new key.
- Test a new key.
- Activate a validated key.
- Rotate active key.
- Disable inactive key.
- Roll back to previous key.

Never allow viewing/copying an existing full secret after it is saved.

### 6.4 Safe Key Rotation Workflow

1. Super admin enters a new key over HTTPS.
2. Backend immediately validates it against a non-mutating provider endpoint.
3. Invalid key is rejected and not activated.
4. Valid key becomes a new Secrets Manager version/secret.
5. Active alias is changed atomically in SSM.
6. Backend gateway cache is invalidated.
7. A safe agent smoke test runs.
8. If smoke test passes, the new key remains active.
9. If it fails, active alias rolls back automatically.
10. Old key remains available for a limited rollback window.
11. Audit event records actor, alias, result, and timestamp, never the key value.

Dynamic reload:

- Backend caches active configuration for a short TTL.
- Admin activation triggers immediate cache invalidation.
- Docker restart is not required.
- If AWS becomes temporarily unavailable, the running process may use the last
  known valid in-memory key.
- The key must never be persisted to an unencrypted local fallback file.

### 6.5 AWS IAM Policy

The backend IAM role/user must have least-privilege access only to:

- Specific SocialHub production secret ARNs.
- Specific SocialHub SSM parameter path.
- Required read/version/update actions.

Do not grant:

```text
secretsmanager:*
ssm:*
Resource: *
```

Frontend/Vercel must not receive this IAM permission.

## 7. Backend Admin APIs

All routes:

```text
/api/v1/admin/*
```

Suggested endpoints:

```text
GET    /api/v1/admin/overview
GET    /api/v1/admin/users
GET    /api/v1/admin/users/{user_id}
GET    /api/v1/admin/users/{user_id}/stats
GET    /api/v1/admin/users/{user_id}/posts

GET    /api/v1/admin/agents
GET    /api/v1/admin/models
POST   /api/v1/admin/agents/{agent_key}/model/test
PATCH  /api/v1/admin/agents/{agent_key}/model
POST   /api/v1/admin/agents/{agent_key}/model/rollback

GET    /api/v1/admin/api-keys
POST   /api/v1/admin/api-keys/test
POST   /api/v1/admin/api-keys
PATCH  /api/v1/admin/api-keys/active
POST   /api/v1/admin/api-keys/rollback

GET    /api/v1/admin/admins
POST   /api/v1/admin/admins/invite
PATCH  /api/v1/admin/admins/{clerk_user_id}/role
DELETE /api/v1/admin/admins/{clerk_user_id}

GET    /api/v1/admin/audit-log
```

Authorization:

| Endpoint group | Minimum role |
|---|---|
| Overview/users/stats | `admin` |
| Agent/model read | `admin` |
| Agent/model change | `super_admin` |
| API-key management | `super_admin` |
| Admin role management | `super_admin` |
| Audit log | `super_admin` |

Backend must return `403` for insufficient roles.

## 8. Frontend Structure

Suggested route structure:

```text
fb_dash/app/admin/
  layout.tsx
  page.tsx
  users/
    page.tsx
    components/
      UsersTable.tsx
      UserDetailsDrawer.tsx
  agents/
    page.tsx
    components/
      AgentsTable.tsx
      ModelSelector.tsx
      ModelTestDialog.tsx
  api-keys/
    page.tsx
    components/
      ApiKeyList.tsx
      AddKeyDialog.tsx
      RotateKeyDialog.tsx
  access/
    page.tsx
  audit/
    page.tsx
  components/
    AdminNav.tsx
    AdminGuard.tsx
    AdminTopBar.tsx
```

Frontend requirements:

- Responsive desktop-first layout.
- User list pagination and search.
- Lazy-load user detail.
- Confirmation dialogs for sensitive actions.
- Do not display hidden-agent traces or prompts.
- Do not display raw AWS/provider errors.
- Do not expose raw API keys.
- Generic loading and failure states.
- `Open User App` in Admin top bar.
- `Admin Panel` in `/agent` profile menu only for admins.

## 9. Smart Implementation Order

### Phase 0: Confirm Scope and Baseline

1. Confirm owner Clerk user ID/email.
2. Confirm desired admin roles.
3. Confirm whether Clerk plan supports required MFA/Organizations features.
4. Run existing frontend/backend tests.
5. Record current Docker image and rollback commands.
6. Do not change database schema.

Deliverable:

- Approved security and role matrix.
- Green test baseline.

### Phase 1: Backend Authorization Foundation

1. Create reusable `require_admin` and `require_super_admin` dependencies.
2. Verify Clerk JWT and session role.
3. Add tests for normal/admin/super-admin access.
4. Add `/api/v1/admin/me` or equivalent role check.

Why first:

No admin UI or sensitive endpoint should exist before backend authorization.

Deliverable:

- Backend-protected empty admin API.

### Phase 2: Frontend Admin Shell and Navigation

1. Add `/admin` layout and server-side role guard.
2. Add Admin navigation.
3. Add `Open User App`.
4. Add admin-only `Admin Panel` item in `/agent`.
5. Verify normal users cannot see or open `/admin`.

Deliverable:

- Secure empty Admin Panel with safe two-way navigation.

### Phase 3: User List and Lazy User Statistics

1. Add paginated users endpoint.
2. Add aggregate per-user statistics endpoint.
3. Avoid N+1 queries.
4. Add Users table.
5. Add click-to-open detail drawer.
6. Add published/pending/failed/cancelled counts.
7. Add connected-platform summary and recent posts.

Deliverable:

- Required user-management visibility without editing user data.

### Phase 4: Admin Access Management

1. Bootstrap owner as `super_admin`.
2. Add existing-user promotion.
3. Add Clerk invitation flow.
4. Add role revocation.
5. Protect last super admin.
6. Add session refresh/revocation behavior.
7. Add MFA requirement if supported.

Deliverable:

- Owner can safely add/remove another admin.

### Phase 5: Read-Only Agent Registry

1. Enumerate Main Agent and `AGENT_REGISTRY`.
2. Return visibility, active model, tier, health, latency, and usage.
3. Add Agents & Models table.
4. Verify this data never enters normal user APIs/UI.
5. Verify the only provider shown is Z.AI.

Deliverable:

- Admin sees all actual agents and current models.

### Phase 6: Approved GLM Model Catalog

1. Create an AWS SSM-backed model catalog from official Z.AI documentation.
2. Add free/paid labels.
3. Add modality compatibility.
4. Add context/pricing metadata.
5. Add experimental/available status.
6. Add capability probes.
7. Add grouped dropdown UI.
8. Verify no model list is hardcoded inside frontend or agent source files.

Deliverable:

- Each agent sees only compatible GLM choices.

### Phase 7: Safe Dynamic Model Switching

1. Store model map in SSM Parameter Store.
2. Add test-model endpoint.
3. Add activate-model endpoint.
4. Add version history and rollback.
5. Invalidate gateway cache on activation.
6. Run post-activation smoke test.
7. Record audit event.

Deliverable:

- Super admin can safely change a model without redeploying Docker.

### Phase 8: Read-Only API-Key Inventory

1. Define secret naming convention.
2. List only safe metadata/aliases.
3. Build API Keys page.
4. Confirm browser never receives raw secrets.

Deliverable:

- Admin can see which key alias is active without changing secrets.

### Phase 9: AWS Secrets Manager Key Rotation

This phase requires explicit approval for:

- AWS IAM changes.
- Secrets Manager writes.
- Server environment/source-of-truth migration.
- Production deployment.

Steps:

1. Create restricted AWS secret paths.
2. Create restricted SSM paths.
3. Migrate current active key from `.env` to Secrets Manager safely.
4. Configure backend secret lookup.
5. Add key test/add/activate/rollback endpoints.
6. Add immediate cache invalidation.
7. Add automatic rollback.
8. Keep `.env` fallback only during controlled cutover.
9. Remove the old plaintext key only after successful verification and explicit
   approval.

Deliverable:

- API key changes apply automatically without container restart.

### Phase 10: Audit and Operational Safety

Initially:

- Write structured audit events to backend/CloudWatch logs.

Events:

- Admin login/access denial.
- Admin invited/promoted/revoked.
- Model tested/changed/rolled back.
- API key tested/added/activated/rolled back.
- User record viewed where appropriate.

Never log:

- Raw API keys.
- OAuth tokens.
- Cookies.
- Passwords.
- Full provider response bodies containing secrets.

If an in-panel persistent audit table is required, add an
`admin_audit_logs` table in a later migration. That migration requires separate
explicit approval.

### Phase 11: Testing and Controlled Rollout

1. Backend authorization tests.
2. User-stat aggregation tests.
3. Agent registry/model catalog tests.
4. Model compatibility tests.
5. Secret non-exposure tests.
6. Key rotation rollback tests.
7. Frontend lint/build/tests.
8. Responsive UI checks.
9. Controlled super-admin test account.
10. Staging/safe production smoke test.
11. Backend Docker deployment only.
12. Frontend GitHub/Vercel deployment.
13. Monitor admin errors, AWS calls, and auth denials.

## 10. Test Matrix

### Authorization

| Test | Expected |
|---|---|
| Signed-out user opens `/admin` | Redirect to login |
| Normal user opens `/admin` | 403/redirect |
| Normal user calls admin API | 403 |
| Admin views Users | Allowed |
| Admin changes API key | 403 |
| Super admin changes model/key | Allowed after confirmation |
| Last super admin removal | Rejected |

### User Statistics

| Data | Expected |
|---|---|
| Published count | Exact `published` rows for selected user |
| Pending count | Exact `pending` rows for selected user |
| Failed count | Exact `failed` rows for selected user |
| Cancelled count | Exact `cancelled` rows for selected user |
| Another user's data | Never mixed |

### Agent Models

| Test | Expected |
|---|---|
| New registered agent | Appears automatically |
| Text agent selects image model | Rejected |
| Non-Z.AI provider/model submitted manually | Rejected |
| Free/paid grouping | Correct |
| Unavailable model | Cannot activate |
| Failed post-activation smoke test | Automatic rollback |
| Model change | Memory remains unchanged |
| User UI | Never shows hidden agents/models |

### API Keys

| Test | Expected |
|---|---|
| Existing key list | Aliases/metadata only |
| Raw existing key response | Never returned |
| Invalid new key | Not stored/activated |
| Valid new key | Stored then activated |
| Failed smoke test | Previous key restored |
| AWS unavailable | Safe error; no corrupted config |
| Browser logs/storage | No secret |

## 11. Acceptance Criteria

- Only authorized admins can access `/admin`.
- Only `super_admin` can manage roles, models, and API keys.
- Normal users never see Admin Panel navigation.
- Admin can switch between `/admin` and `/agent` without re-login.
- User list is paginated and searchable.
- Details load only when a user is selected.
- Published/pending/failed counts match database fixtures exactly.
- Agent count is derived dynamically from the registry.
- Main Agent and hidden agents are correctly labeled.
- Each agent shows its current model.
- GLM dropdown clearly groups free and paid models.
- Incompatible/unavailable models cannot activate.
- Model changes are validated, versioned, and reversible.
- Model changes do not delete memory or workflow state.
- Raw API keys never reach the frontend.
- API-key rotation is validated and automatically reversible.
- AWS access follows least privilege.
- Every sensitive action creates an audit event.
- Existing agent/user workflows remain unbroken.
- Frontend lint/build/tests pass.
- Backend tests pass.

## 12. Deployment and Repository Rules

Frontend:

- Implement under `fb_dash/`.
- Run lint, build, and tests.
- Commit/push only from `fb_dash/`.
- Vercel deploys through the frontend GitHub flow.

Backend:

- Implement under `fb_agent/`.
- Do not push backend changes to GitHub.
- Deploy backend through SCP and Docker only.
- Use the `socialhub-api` container name.
- Use `/home/ubuntu/fb_agent/.env` during the controlled cutover.

Root documentation:

- This plan belongs to the root repository.
- Root documentation commits remain separate from frontend/backend code.

Database:

- Initial admin implementation should not require a migration.
- A persistent in-panel audit table requires explicit migration approval.

AWS:

- IAM, Secrets Manager, SSM, and production secret changes require explicit
  approval before implementation.

## 13. Rollback Plan

- Retain the previous frontend deployment.
- Retain the previous backend Docker image.
- Keep the previous active API-key secret version during the rollback window.
- Version every agent model-map update.
- Provide one-click model rollback.
- Automatically roll back failed key/model activations.
- Never modify user memory during model changes.
- Do not alter the database schema in the initial rollout.
- If admin functionality fails, disable `/admin` while preserving `/agent`.

## 14. Final Recommended Delivery Sequence

```text
1. Backend admin authorization
2. Frontend admin shell and UI switch
3. Users list and click-to-load statistics
4. Admin invitation/role management
5. Read-only agent registry
6. GLM model catalog and free/paid dropdown
7. Safe dynamic model switching with rollback
8. Read-only API-key aliases
9. AWS Secrets Manager/SSM integration
10. Dynamic key rotation with rollback
11. Audit logging
12. Full testing
13. Controlled Docker/Vercel rollout
```

This order intentionally secures access before displaying data, implements
read-only visibility before mutation controls, and delays API-key mutation until
AWS permissions, rollback, and auditing are ready.

## 15. Research Sources

- Clerk basic RBAC:
  <https://clerk.com/docs/guides/secure/basic-rbac>
- Clerk Organization roles and permissions:
  <https://clerk.com/docs/guides/organizations/control-access/roles-and-permissions>
- Clerk invitations:
  <https://clerk.com/docs/organizations/invitations>
- Stripe team access and MFA:
  <https://docs.stripe.com/get-started/account/orgs/team>
- Shopify user roles:
  <https://help.shopify.com/en/manual/your-account/users>
- Refine GitHub:
  <https://github.com/refinedev/refine>
- React Admin GitHub:
  <https://github.com/marmelab/react-admin>
- SQLAdmin GitHub:
  <https://github.com/smithyhq/sqladmin>
- Z.AI model overview:
  <https://docs.z.ai/guides/overview/overview>
- Z.AI model pricing:
  <https://docs.z.ai/guides/overview/pricing>
- Z.AI Chat Completion API:
  <https://docs.z.ai/api-reference/llm/chat-completion>
- Z.AI GLM-5.2:
  <https://z.ai/blog/glm-5.2>
- Z.AI General API:
  <https://docs.z.ai/api-reference/introduction>
- AWS Secrets Manager:
  <https://docs.aws.amazon.com/secretsmanager/>
- AWS Systems Manager Parameter Store:
  <https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html>
