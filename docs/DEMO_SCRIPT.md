# Demo Script — DocuFlow AI 5 Dakikalık Test

Bu rehber, projeyi kendi makinenizde çalıştırıp 5 dakikada uçtan uca test
etmenizi sağlar. Her adımda **ne görmeniz gerektiği** yazılıdır. Görsel
referanslar [`docs/screenshots/`](screenshots/) klasöründedir.

## 0. Ön Koşullar

- **Docker Desktop** (Windows/Mac/Linux) — `docker compose` çalışır olmalı.
- **Groq API key** (ücretsiz): https://console.groq.com/keys
- Port 3000 (web) ve 8000 (api) başka uygulama tarafından tutulmuyor olmalı.

## 1. Klonla ve .env oluştur

```bash
git clone <repo-url>
cd docuflow-ai
cp .env.example .env
```

`.env` dosyasını açın, `GROQ_API_KEY` satırına anahtarınızı yazın.
Diğer tüm değerler varsayılanlarıyla çalışır.

**Beklenen çıktı:** `.env` dosyasında `GROQ_API_KEY` dolu (boş değil).

## 2. Servisleri başlat

```bash
docker compose up -d
```

**Beklenen çıktı:** `docker compose ps` üç servisin `Up` olduğunu gösterir:

| Servis   | Port  | Not                                    |
|----------|-------|----------------------------------------|
| postgres | 5432  | pgvector dahil, healthcheck: healthy   |
| api      | 8000  | FastAPI, `/health` → `{"status":"ok"}` |
| web      | 3000  | Next.js production build               |

> İlk build 5-10 dk sürebilir (torch + sentence-transformers indirilir).
> Sonraki çalıştırmalar ~30 sn'dir.

## 3. Demo veriyi yükle

```bash
docker compose exec api python -m scripts.seed_data
```

**Beklenen çıktı:**
`15 doküman oluşturuldu, 0 zaten vardı, N chunk indexlendi`
(N ≈ 38). Script idempotent'tir; ikinci kez çalıştırırsanız
`0 doküman oluşturuldu, 15 zaten vardı, 0 chunk indexlendi` yazar.

## 4. Tarayıcıda aç ve giriş yap

Tarayıcıda http://localhost:3000 açın.

**Beklenen çıktı:** Login ekranı → **Kullanıcı: demo, Şifre: x** → Dashboard
açılır; solda "Dokümanlar" ve "AI Asistan" menüleri görünür.

## 5. 5 Dakikalık Test Senaryosu

### Adım 1 — Doküman listesi (0:00–1:00)

**Beklenen çıktı:** Grid'de 19 doküman kartı (15 seed + var olan diğerleri);
her kartta başlık, tarih ve 2 satırlık içerik önizlemesi.

📸 `screenshots/01-dashboard.png`

### Adım 2 — Chat: RAG sorusu (1:00–2:00)

"AI Asistan" sayfasına geçin, **Chat** modunda şunu yazın:

> Sözleşmelerdeki ödeme koşulları neler?

**Beklenen çıktı:** Cevap token token akar (streaming, yanıp sönen imleç);
cevabın altında **"📎 Kaynaklar (N)"** — hangi dokümanın hangi benzerlik
skoruyla kullanıldığı listelenir (örn. "Hizmet Sözleşmesi — benzerlik 0.78").

📸 `screenshots/02-chat-rag.png`

### Adım 3 — Agent: Özet (2:00–3:00)

Modu **Agent** yapın. Doküman seçiciden **Freelance Sözleşmesi**'ni seçin:

> Bu sözleşmeyi özetle

**Beklenen çıktı:** Cevabın üstünde `intent: summarize` etiketi; 3-5 cümlelik
özet + ana noktalar. Seçili doküman yoksa sayfa sizi uyarır.

📸 `screenshots/03-agent-summarize.png`

### Adım 4 — Agent: Aksiyon maddeleri (3:00–4:00)

Seçimi temizleyip **Haftalık Sprint Toplantısı**'nı seçin:

> Yapılacakları çıkar

**Beklenen çıktı:** `intent: extract_actions` etiketi; sorumlu/tarih içeren
checkbox listesi (örn. "- [ ] Ali: Arama sorgusuna veritabanı indeksi ekle
(Çarşamba)").

📸 `screenshots/04-agent-extract-actions.png`

### Adım 5 — Agent: Karşılaştırma (4:00–5:00)

**Hizmet Sözleşmesi** ve **Gizlilik Sözleşmesi**'ni birlikte seçin:

> Bu iki sözleşmeyi karşılaştır

**Beklenen çıktı:** `intent: compare` etiketi; madde madde fark tablosu +
ortak noktalar + farklar (süre, ceza, fesih koşulları vb.).

📸 `screenshots/05-agent-compare.png`

## 6. Sorun Giderme

- **Port çakışması:** 3000'de başka bir uygulama çalışıyorsa onu durdurun
  (örn. host'ta açık bir `npm run dev`).
- **API cevap vermiyor:** `docker compose logs api` — Groq key'inin `.env`'de
  dolu olduğundan emin olun; `.env` değiştiyse `docker compose up -d api`
  gerekir (restart yetmez).
- **Testler için test DB:** `pytest` koşulacaksa (opsiyonel):
  ```bash
  docker compose exec postgres psql -U docuflow -d docuflow -c "CREATE DATABASE docuflow_test OWNER docuflow;"
  ```
  ("already exists" hatası sorun değildir — DB zaten var demektir.)
- **Yeniden başlatma:** Tüm stack'i sıfırlamak için
  `docker compose down` (veriler `docker compose down -v` ile silinir).
