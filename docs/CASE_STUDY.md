# Case Study: DocuFlow AI

> Upwork brief'indeki *"Please share one relevant AI SaaS project and explain what
> you personally built."* sorusuna detaylı cevap. Müşteri "detaylı göster" derse
> bu dosya paylaşılır.

## 1. Problem & Brief

The brief asked for an AI feature inside an existing SaaS, with a specific stack:
Python + FastAPI + LangGraph + RAG + Next.js. DocuFlow AI answers it directly:
an AI assistant layer on top of a B2B document management SaaS where users ask
questions about their documents and get streamed, source-cited answers — or
delegate multi-step tasks (summarize, extract action items, compare two
documents) to an agent.

## 2. Solution Architecture

```text
Browser ── SSE ──▶ Next.js 14 ── REST + SSE ──▶ FastAPI (async)
                                                  │
                                     ┌────────────┴────────────┐
                                     │  LangGraph agent        │
                                     │  router + 4 tools       │
                                     └────────────┬────────────┘
                                                  │
                               PostgreSQL 16 + pgvector (documents, chunks)
```

Three containers (postgres + api + web) start with one command. Embeddings are
produced locally by sentence-transformers, so the only external runtime
dependency is the Groq LLM API — reached through a single abstraction layer
(`app/core/llm.py`).

## 3. My Role

I built the entire AI layer end to end, alone:

- **Backend** — async FastAPI routers (auth, documents, AI), SQLAlchemy 2.0
  models, Alembic migrations, JWT auth with deterministic mock users, and a
  47-test pytest suite with isolated test database.
- **AI** — chunking (800 chars / 100 overlap), local embedding + pgvector
  cosine search, RAG chat service, LangGraph agent (typed state, router node,
  retrieve node, 4 tool nodes), SSE streaming of `intent → sources → token×N →
  done` events.
- **Frontend** — Next.js 14 App Router, TypeScript strict, Zustand auth store,
  custom SSE client (fetch + ReadableStream), streaming chat UI, agent UI with
  document selector.
- **Infra** — Docker Compose, multi-stage production frontend build, idempotent
  seed script with 15 realistic Turkish B2B documents, test-DB isolation so
  pytest never touches dev data.

## 4. Technical Decisions

- **pgvector over Pinecone/Weaviate** — stays inside Postgres: no extra
  service, JOIN-based owner filtering, zero added cost. Ample headroom below
  ~1M chunks.
- **bge-small-en-v1.5 over OpenAI embeddings** — free, offline, 384-dim
  (fast to search); quality is sufficient for contracts, project plans and
  meeting notes.
- **Groq over OpenAI/Anthropic** — OpenAI-compatible endpoint, very fast
  inference, free tier; the abstraction layer makes swapping providers a
  one-line change.
- **LangGraph over a hand-rolled router** — typed state, conditional edges and
  tool abstraction. Tool nodes prepare prompts only; the final LLM call is
  streamed, so one LLM request per task.
- **SSE over WebSocket** — one-way stream, proxy-friendly, plain HTTP/1.1.
  Since the endpoints are POST, EventSource doesn't fit; I wrote a custom
  fetch + ReadableStream client.

## 5. Hard Parts & Solutions

1. **An SSE bug that looked like a backend failure.** The API returned 200 and
   3.6 kB of data, but the UI never rendered a single token. The cause was
   invisible at the HTTP layer: the server framed events with CRLF line
   endings, and the standard parser searches for `\n\n` — which never occurs
   inside `\r\n\r\n` framing. I proved it with raw packet inspection
   (`curl | od -c`) and fixed the client parser by normalizing line endings.
   Lesson: protocol-level bugs hide in bytes, not in status codes.

2. **Connection leaks in long-lived streams.** A streaming response holds its
   DB session for the entire stream; a client that disconnected early left the
   session dangling and, over repeated requests, would exhaust the pool.
   Solution: sessions are closed in `finally` blocks inside the stream
   generator; repeated-request testing confirmed a stable pool.

3. **Native dependencies on Windows.** sentence-transformers crashed on the dev
   machine with a missing DLL; adding `msvc-runtime` fixed it, and setting
   `HF_HUB_OFFLINE=1` stopped tests from hitting the network for etag checks
   (which had caused flaky failures). Lesson: containers make ML dependencies
   reproducible — document host setup separately.

## 6. Results & Learnings

47 passing tests, streaming end to end, a 5-minute demo script anyone can
follow. Key learnings: SSE is simple only until line endings bite — always
validate the raw stream first; local embeddings + pgvector keep an MVP's
operational cost near zero; typing the agent state explicitly saves hours of
confusion when conditional edges grow.

## 7. How I'd Apply It

The core is directly portable to the client's SaaS:

- The ownership model already isolates data per user (`owner_id`) → it
  generalizes to `org_id` for multi-tenant isolation.
- Mock auth → real user database (registration, password hashing, refresh
  token flow).
- The document model gains file upload (PDF/DOCX) → parse → the same ingestion
  pipeline, unchanged.
- Scale path: embeddings are stored raw, so beyond ~10M vectors pgvector can
  be swapped for a dedicated vector DB without re-embedding.
- Rate limiting, structured logging, CI/CD and HTTPS reverse proxy are already
  listed as the MVP's explicit production roadmap.

In a 1-3 month engagement I would start with the client's highest-value
document workflow — ingest → ask → act — and iterate with weekly demos.
