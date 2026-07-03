# Database

Production uses PostgreSQL; supported local tests may use SQLite. SQLAlchemy and Alembic
own application schema.

Existing agent tables: workflows, runs, artifacts, confirmations, and memories.

Important migrations:

- `f2c9d8e1a7b4_remove_user_prompt_provider_fields.py`
- `a9b7c6d5e4f3_add_agent_workflow_memory_tables.py`
- `b4e8f1a9c2d3_add_clerk_user_sync_fields.py`

LangGraph checkpoint schema needs explicit migration approval. Operational checkpoints
do not replace product artifacts/audit. Never alter schema/data without approval and
tested rollback.

