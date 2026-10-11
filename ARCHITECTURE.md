# DocuFlow AI — Mimari

## 1. Genel Bakış

DocuFlow AI, mevcut bir B2B doküman yönetimi SaaS'ına eklenen AI asistan katmanıdır.
Kullanıcılar dokümanlarına doğal dille soru sorabilir (RAG), özet çıkarabilir,
aksiyon maddeleri toplayabilir ve iki dokümanı karşılaştırabilir (LangGraph agent).
MVP'de auth ve doküman yönetimi mock'lanmıştır; odak AI katmanıdır.

## 2. Yüksek Seviye Mimari

```
┌──────────────┐            ┌──────────────┐
│   Browser    │───────────▶│  Next.js 14  │
│ (localhost)  │◀───────────│    (web)     │
└──────────────┘    SSE     └──────┬───────┘
                                   │ REST + SSE
                                   ▼
                        ┌──────────────────┐
                        │   FastAPI (api)  │
                        │  ─ /api/auth     │
                        │  ─ /api/documents│
                        │  ─ /api/ai/*     │
                        └────┬────────┬────┘
                             │        │
                  ┌──────────▼──┐  ┌──▼─────────────┐
                  │  LangGraph  │  │  Groq LLM API  │
                  │    Agent    │  │   (llama/qwen) │
                  │ router + 4  │  └────────────────┘
                  │    tools    │
                  └──────┬──────┘
                         │
              ┌──────────▼────────────┐
              │   PostgreSQL 16 +     │
              │       pgvector        │
              │ (documents, chunks)   │
              └───────────────────────┘
```

## 3. Katmanlar

**Frontend (Next.js App Router):**
- `src/app/` — sayfalar (login, dashboard, assistant)
- `src/components/` — UI bileşenleri (LoginForm, DocumentCard, MessageBubble, DocumentSelector)
- `src/lib/` — api.ts (fetch wrapper), sse.ts (SSE client), store.ts (Zustand auth)

**API (FastAPI routers):**
- `app/api/auth.py` — login, me
- `app/api/documents.py` — CRUD + index
- `app/api/ai.py` — search, chat (SSE), agent (SSE)
- `app/api/deps.py` — JWT dependency

**Services (business logic):**
- `DocumentService` — CRUD, owner filtresi
- `IngestionService` — chunk + embed
- `RAGService` — semantic search + get_all_chunks
- `ChatService` — basit RAG chat stream
- `AgentService` — LangGraph stream

**Agent (LangGraph):**
- `app/agent/state.py` — AgentState TypedDict
- `app/agent/nodes.py` — router_node, retrieve_node, tool nodes
- `app/agent/graph.py` — StateGraph tanımı + conditional edges

**Core:**
- `app/core/config.py` — Pydantic Settings (.env okuma)
- `app/core/db.py` — async SQLAlchemy engine + Base + get_db
- `app/core/llm.py` — get_llm (Groq) + LocalEmbeddings (bge-small)
- `app/core/security.py` — JWT create/decode

**Models (SQLAlchemy):**
- `Document` — id, title, content, owner_id, source, created_at
- `Chunk` — id, document_id (FK cascade), content, embedding vector(384), chunk_index

**Schemas (Pydantic):**
- Auth: LoginRequest, TokenResponse, UserInfo
- Documents: DocumentCreate, DocumentUpdate, DocumentRead, DocumentListItem, DocumentListResponse
- AI: IndexResponse, SearchRequest, SearchResponse, ChatRequest, ChatSource, ...

## 4. RAG Akışı

1. **Ingestion:** Doküman oluşturulunca `POST /api/documents/{id}/index`
   → chunk_text() (RecursiveCharacterTextSplitter, 800 char, 100 overlap)
   → embeddings.embed_documents() (batch, bge-small-en-v1.5, normalize)
   → her chunk + vektör chunks tablosuna eklenir (pgvector)

2. **Search:** Sorgu gelince `RAGService.search(query, document_ids, limit)`
   → query embed edilir
   → `cosine_distance(chunks.embedding, query_vector)` SQL sorgusu
   → JOIN documents (owner filtresi)
   → ORDER BY similarity DESC LIMIT N
   → MIN_SIMILARITY=0.55 eşiği altındaki sonuçlar elenir

## 5. Agent Akışı (LangGraph)

```
START → router_node
          │
          ├─ intent=qa → retrieve → qa_node → END
          ├─ intent=summarize → retrieve → summarize_node → END
          ├─ intent=extract_actions → retrieve → extract_node → END
          └─ intent=compare → retrieve → compare_node → END
```

- **router_node:** LLM'e kısa prompt (max_tokens=10) → intent sınıflandırma
- **retrieve_node:** intent'e göre davranış değişir:
  - qa → semantic search (RAGService.search)
  - summarize/extract_actions → ilk dokümanın tüm chunk'ları (get_all_chunks)
  - compare → ilk 2 dokümanın tüm chunk'ları
- **tool node'ları:** LLM çağrısı YAPMAZ, sadece system_prompt + user_prompt hazırlar
- **AgentService.stream_agent:** graph.ainvoke() ile state hesaplar, sonra LLM'e stream eder → SSE event'leri: intent → sources → token×N → done

## 6. Karar Notları

| Karar | Neden |
|-------|-------|
| **pgvector** (Pinecone/Weaviate değil) | Postgres içinde, ek servis yok, MVP için yeterli, ücretsiz |
| **bge-small-en-v1.5** (OpenAI embeddings değil) | Ücretsiz, offline, 384d (hızlı), kalite yeterli |
| **Groq** (OpenAI/Anthropic değil) | Hızlı inference, ücretsiz tier, OpenAI-uyumlu API |
| **SSE** (WebSocket değil) | Tek yönlü stream için basit; proxy dostu; HTTP/1.1 uyumlu |
| **LangGraph** (basit router değil) | Conditional routing + tool abstraction + state yönetimi |
| **Zustand** (Redux değil) | Hafif, boilerplate yok, sadece auth için yeterli |
| **SSE client = fetch + ReadableStream** (EventSource değil) | EventSource sadece GET destekler, bizim endpoint'ler POST |

## 7. Klasör Yapısı (Gerçek)

```
docuflow-ai/
├── backend/
│   ├── app/
│   │   ├── agent/          # LangGraph (state, nodes, graph)
│   │   ├── api/            # FastAPI routers (auth, documents, ai, deps)
│   │   ├── core/           # config, db, llm, security
│   │   ├── models/         # SQLAlchemy (Document, Chunk)
│   │   ├── schemas/        # Pydantic (auth, document, ai)
│   │   └── services/       # document, ingestion, rag, chat, agent, chunking, prompts
│   ├── alembic/            # migrations
│   ├── scripts/            # seed_data.py
│   ├── tests/              # 47 pytest test
│   ├── pyproject.toml
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── app/            # Next.js App Router (/, /dashboard, /dashboard/assistant)
│   │   ├── components/     # LoginForm, DocumentCard, NewDocumentModal, MessageBubble, DocumentSelector
│   │   └── lib/            # api.ts, sse.ts, store.ts, format.ts, uuid.ts
│   ├── public/
│   ├── next.config.js      # output: "standalone"
│   ├── package.json
│   └── Dockerfile          # multi-stage production build
├── scripts/
│   └── init-db.sh          # postgres init (docuflow_test DB)
├── docker-compose.yml      # postgres + api + web
├── .env.example
├── README.md
├── ARCHITECTURE.md         # bu dosya
└── CLAUDE.md
```
