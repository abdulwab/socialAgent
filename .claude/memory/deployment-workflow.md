# Deployment Workflow

Frontend:

- verify lint, build, tests
- commit/push only inside `fb_dash` when requested
- Vercel deploys from the frontend GitHub workflow

Backend:

- never push backend to GitHub
- verify targeted and full tests
- obtain deployment approval
- SCP reviewed files to `/home/ubuntu/fb_agent/`
- build `socialhub-backend`; run `socialhub-api`
- use server env `/home/ubuntu/fb_agent/.env`
- verify container, logs, OpenAPI, and `/health`

Use `fb_agent/AWS-DEPLOY-GUIDE.md`. Never print or replace the server environment.

