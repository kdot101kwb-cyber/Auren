# AUREN AI provider secret

The callable `aurenAiGateway` reads `AUREN_AI_API_KEY` through Firebase Functions Secret Manager. The key is never stored in source code.

One-time deployment setup:

```bash
firebase functions:secrets:set AUREN_AI_API_KEY
firebase deploy --only functions:aurenAiGateway
```

Optional runtime configuration:
- `AUREN_AI_MODEL` defaults to `gpt-4o-mini`.
- `AUREN_AI_BASE_URL` defaults to `https://api.openai.com/v1`.

Do not paste the API key into GitHub, source files, or chat messages.
