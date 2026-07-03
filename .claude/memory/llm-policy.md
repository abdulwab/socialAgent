# LLM Policy

Exactly one backend gateway:

```text
fb_agent/app/services/agent_llm_gateway.py
```

Model configuration:

```text
fb_agent/app/config/glm_models.json
```

- Z.AI key/base URL are backend/server environment values.
- Do not add provider branches or user-facing key/provider/model controls.
- Do not hardcode model policy in agents/nodes.
- All LangGraph nodes use the same gateway adapter.
- Validate structured output and apply deterministic checks.
- Never send secrets or OAuth credentials to the model.

