# CLAUDE.md — DocuFlow AI Assistant

## Ne yapıyoruz
DocuFlow adında mevcut bir B2B doküman yönetimi SaaS'ına "AI Asistan" özelliği ekliyoruz.
Mevcut ürünün auth/doküman yönetimi kısımları mock'lanacak; bizim işimiz AI katmanı.

## Kapsam
- RAG tabanlı doküman Q&A (streaming, kaynak gösterimli)
- LangGraph agent ile çok adımlı görevler:
  * özet çıkarma
  * aksiyon maddeleri çıkarma
  * iki dokümanı karşılaştırma
- FastAPI backend + Next.js 14 frontend

## Tech stack
- Backend: Python 3.11, FastAPI, SQLAlchemy 2.0, Alembic, Pydantic v2
- AI: LangGraph, LangChain
- LLM: Groq (OpenAI-uyumlu endpoint) — model: qwen/qwen3.8-27b
- Embeddings: yerel sentence-transformers (BAAI/bge-small-en-v1.5, 384 dim)
- DB: PostgreSQL 16 + pgvector
- Frontend: Next.js 14 (App Router), TypeScript, Tailwind, shadcn/ui
- Infra: Docker Compose

## Kurallar
- Python: ruff + black, type hints zorunlu, async FastAPI
- TS: strict mode, ESLint
- Her yeni endpoint için pytest testi yaz
- Sırlar .env'de, koda gömme
- LLM çağrıları için her zaman abstraction kullan (app/core/llm.py)
- Streaming için SSE kullan (WebSocket değil)
- Commit mesajları conventional commits formatında

## Klasör yapısı
(bkz. ARCHITECTURE.md)
