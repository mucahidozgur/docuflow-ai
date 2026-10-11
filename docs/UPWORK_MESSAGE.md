
Hi,

Your brief asks for an AI SaaS feature with Python + FastAPI + LangGraph + RAG + Next.js. I built exactly that — a working, end-to-end project you can run in 5 minutes.

DocuFlow AI adds an AI assistant layer to a B2B document management SaaS: RAG-powered Q&A with cited sources, plus a LangGraph agent for summaries, action items, and document comparison. One command starts the whole stack.

What I personally built:

- **Backend** — async FastAPI, SQLAlchemy 2.0, Alembic, JWT auth, 47 pytest tests.
- **AI** — RAG pipeline (chunking → local embeddings → pgvector cosine search), LangGraph agent (router + 4 tools), SSE streaming.
- **Frontend** — Next.js 14 App Router, TypeScript, Tailwind, custom SSE client, streaming chat + agent UI with document selector.
- **Infra** — Docker Compose (postgres + api + web), multi-stage production frontend build.

Notable technical challenges:

- **SSE CRLF bug** — the server framed events with CRLF line endings, which a standard `\n\n` parser never detects. Root-caused it with raw packet inspection and fixed the client parser.
- **StreamingResponse connection leak** — early client disconnects left DB sessions open; moved cleanup into `finally` blocks and verified a stable pool.

---

You can see it running end-to-end in 5 minutes — the repo (with a demo
script, screenshots, and a 47-test suite) is on GitHub:
https://github.com/mucahidozgur/docuflow-ai

I can walk you through it on a quick call, or just run it yourself:
`docker compose up -d` and login as `demo` / `x`.

---

I can adapt this project to your SaaS within a 1-3 month engagement. As a first step, let's talk about which feature you'd like to start with.

Best regards,
Özgür Çiçek
