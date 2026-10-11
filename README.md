# DocuFlow AI

Mevcut bir B2B doküman yönetimi SaaS'ına eklenen AI asistan özelliği.
RAG tabanlı soru-cevap + LangGraph agent ile özet/aksiyon/karşılaştırma.

## ✨ Özellikler

- 🔐 JWT auth (mock user - prod için hazır değil)
- 📄 Doküman CRUD + otomatik embedding (pgvector)
- 💬 RAG chat (SSE streaming, kaynak gösterimli)
- 🤖 LangGraph agent: router + 4 tool (qa, summarize, extract_actions, compare)
- 🎨 Next.js 14 frontend (chat UI, agent UI, doküman seçici)
- 🐳 Tek komutla çalışır (docker compose up -d)

## 🛠️ Tech Stack

Backend:
- Python 3.11
- FastAPI + SQLAlchemy 2.0 (async)
- Alembic (migrations)
- Pydantic v2

AI:
- LangGraph (agent orchestration)
- LangChain (LLM abstractions)
- Groq API (OpenAI-uyumlu endpoint)
- sentence-transformers (bge-small-en-v1.5, 384d) — offline embedding

Veritabanı:
- PostgreSQL 16 + pgvector

Frontend:
- Next.js 14 (App Router)
- TypeScript + Tailwind CSS
- Zustand (state)
- Native fetch + ReadableStream (SSE client)

Infra:
- Docker Compose (postgres + api + web)

## 🚀 Hızlı Başlangıç

### Gereksinimler
- Docker Desktop (Windows/Mac/Linux)
- Groq API key (ücretsiz): https://console.groq.com/keys

### 1. Klonla ve .env oluştur
```bash
git clone <repo-url>
cd docuflow-ai
cp .env.example .env
# .env içindeki GROQ_API_KEY değerini doldur
```

### 2. Servisleri başlat
```bash
docker compose up -d
```

İlk çalıştırmada build 5-10 dk sürebilir (torch + sentence-transformers indirilir).
Sonraki çalıştırmalar hızlıdır (~30 sn).

### 3. Demo veriyi yükle (opsiyonel ama önerilir)
```bash
docker compose exec api python -m scripts.seed_data
```

15 gerçekçi Türkçe B2B dokümanı (sözleşme, proje, toplantı, rapor) oluşturur ve indexler.

### 4. Aç
```
http://localhost:3000
```

Demo login:
- Kullanıcı: demo
- Şifre: x

## 💡 Kullanım Örnekleri

Basit soru (Chat modu):
> Sözleşmelerdeki ödeme koşulları neler?

→ RAG ile ilgili chunk'lar bulunur, LLM streaming yanıt üretir, kaynaklar listelenir.

Özet çıkarma (Agent modu):
> [Freelance Sözleşmesi seçili] Bu sözleşmeyi özetle

→ intent: summarize → 3-5 cümlelik özet + ana noktalar.

Aksiyon maddeleri (Agent modu):
> [Haftalık Sprint seçili] Yapılacakları çıkar

→ intent: extract_actions → checkbox listesi (sorumlu/tarih ile).

Karşılaştırma (Agent modu):
> [Hizmet + Gizlilik Sözleşmesi seçili] Bu iki sözleşmeyi karşılaştır

→ intent: compare → markdown tablo + ortak noktalar + farklar.

## 🧪 Testler

```bash
cd backend
pytest -v
# 47 test, hepsi passing
```

Not: İlk çalıştırmada test DB'si gerekebilir:
```bash
docker compose exec postgres psql -U docuflow -d docuflow -c "CREATE DATABASE docuflow_test OWNER docuflow;"
```

## 📡 API Endpoints

| Method | Path | Açıklama |
|--------|------|----------|
| POST | /api/auth/login | Mock login (username, password) → JWT |
| GET | /api/auth/me | Token doğrulama + user info |
| POST | /api/documents | Yeni doküman |
| GET | /api/documents | Liste (sayfalama) |
| GET | /api/documents/{id} | Tek doküman |
| PUT | /api/documents/{id} | Güncelle |
| DELETE | /api/documents/{id} | Sil |
| POST | /api/documents/{id}/index | Chunk + embed |
| POST | /api/ai/search | RAG semantic search |
| POST | /api/ai/chat | SSE streaming chat (basit RAG) |
| POST | /api/ai/agent | SSE streaming agent (router + tools) |

## 📁 Proje Yapısı

(bkz. ARCHITECTURE.md)

## 🔧 Geliştirme

Frontend'i host'ta çalıştırmak istersen:
```bash
cd frontend
npm install
npm run dev
```

API ve DB container'da çalışmaya devam eder.

## ⚠️ Prod için TODO

Bu MVP'dir. Prod'a çıkmadan önce:

- [ ] Mock auth yerine gerçek kullanıcı DB'si (register, password hash)
- [ ] Refresh token akışı (kısa access + uzun refresh)
- [ ] Rate limiting (per-user, per-IP)
- [ ] Sentry / structured logging
- [ ] Real test suite (ayrı test DB + fixture cleanup)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] HTTPS + reverse proxy (nginx/traefik)
- [ ] Doküman upload (PDF, DOCX) → parse → ingest
- [ ] Multi-tenant (org_id izolasyonu)
- [ ] Backup stratejisi (pg_dump otomatik)

## 📄 Lisans

MIT

## 📚 Ek Dokümantasyon

- [Upwork Başvuru Mesajı](docs/UPWORK_MESSAGE.md)
- [Demo Script](docs/DEMO_SCRIPT.md)
- [Case Study](docs/CASE_STUDY.md)
- [Screenshots](docs/screenshots/)
