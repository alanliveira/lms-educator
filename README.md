# Educator LMS

LMS multi-tenant (Rails 7 + Hotwire + Tailwind) com autenticação por subdomínio, cursos, turmas, certificados e e-mails via Resend.

## Pré-requisitos

- Ruby **3.3.0** / Node **22.1.0** (recomendado via [`mise`](https://mise.jdx.dev) — ver `.tool-versions`)
- Postgres **16** e **Redis** (ou use o `docker-compose.yml`, que sobe o Postgres)
- `yarn` e `bundler`

## Setup local

> Passo a passo detalhado (dependências, `.env`, Supabase local, troubleshooting): [`development.md`](development.md).

```bash
mise install                      # instala versões do .tool-versions
cp .env.sample .env               # e preencha as variáveis (ver tabela abaixo)
bundle install
yarn install
docker compose up -d db           # só Postgres, ou use um Postgres local
bin/rails db:prepare
yarn build && yarn build:css
bin/dev                           # server + assets (Procfile.dev)
```

Testes:

```bash
bin/rails test                    # ou: bundle exec rspec
bundle exec rubocop
```

## Variáveis de ambiente

Copie `.env.sample` para `.env` (ignorado pelo Git) e preencha:

| Variável | Obrigatória | Descrição |
|---|---|---|
| `DATABASE_URL` | Sim | Conexão Postgres. Local: `postgres://postgres:postgres@localhost:5432/educator_lms_development` |
| `TEST_DATABASE_URL` | Não | Postgres de testes (padrão em `.env.sample`) |
| `RAILS_ENV` | Não | `development` / `test` / `production` (padrão: development) |
| `RAILS_MASTER_KEY` | Em produção | Descriptografa `config/credentials.yml.enc` |
| `REDIS_URL` | Sim | Redis para Action Cable (`config/cable.yml`) |
| `RESEND_API_KEY` | Sim | Chave de API do Resend (envio de e-mail) |
| `EMAIL_ADMINISTRATION_SYSTEM` | Sim | Remetente padrão dos e-mails (ex.: `no-reply@seudominio.com`) |
| `EMAIL_HOST` | Sim | Host usado nos links dos e-mails (ex.: `educator.app.br`, `localhost:3000`) |
| `SUPABASE_STORAGE_ENDPOINT` | Em produção | Endpoint S3 do Supabase (Active Storage `:supabase`) |
| `SUPABASE_KEY` | Em produção | Access key ID do S3 do Supabase |
| `SUPABASE_KEY_SECRET` | Em produção | Secret access key do S3 do Supabase |
| `COMPANY_DEFAULT_ID` | Sim | `id` da `Company` padrão usada nos e-mails |
| `WEB_CONCURRENCY` | Não | Workers do Puma em produção (padrão: nº de CPUs) |
| `RAILS_LOG_LEVEL` | Não | `info` / `debug` (padrão: `info`) |
| `RAILS_MAX_THREADS` / `RAILS_MIN_THREADS` | Não | Threads do Puma (padrão: `5`) |
| `RAILS_DEVELOPMENT_HOST` | Não | Host liberado em development (padrão: `localhost:3000`) |
| `PORT` | Não | Porta do servidor (padrão: `3000`) |
| `AZURE_ACTIVE_STORAGE` | Não | Só se usar o serviço `:microsoft` — não é o default |

### Como obter cada variável

- **`DATABASE_URL`** — Local: use o Postgres do `docker compose up -d db` (credenciais do `docker-compose.yml`). Produção: painel do Render → *Databases* → *Connection strings* → *External*.
- **`RAILS_MASTER_KEY`** — Chave que descriptografa `config/credentials.yml.enc` (o `config/master.key` é ignorado pelo Git). Se você já tem o arquivo `config/master.key` localmente, copie o valor. Senão, em uma cópia do projeto que tenha a chave: `bin/rails credentials:show`. **Atenção:** sem essa chave os credentials não podem ser recuperados — guarde em um cofre.
- **`RESEND_API_KEY`** — [resend.com](https://resend.com) → *API Keys* → *Create Key*.
- **`EMAIL_ADMINISTRATION_SYSTEM`** — No Resend: *Domains* → adicionar e verificar o domínio do remetente; o endereço precisa pertencer a um domínio verificado.
- **`EMAIL_HOST`** — Domínio público onde a app roda (produção: `educator.app.br` / `aprenda.seetech.com.br`; local: `localhost:3000`).
- **`SUPABASE_*`** — Supabase Dashboard → *Project Settings* → *Storage* → *S3 API* → *Create new credentials*. O endpoint tem o formato `https://<project-ref>.storage.supabase.co/storage/v1/s3`. O bucket usado é `contents-class` (`config/storage.yml`).
- **`REDIS_URL`** — Local: `redis://localhost:6379/1`. Produção: Upstash Redis, Render Redis ou similar.
- **`COMPANY_DEFAULT_ID`** — `bin/rails runner 'puts Company.first.id'` no ambiente desejado.
- **`AZURE_ACTIVE_STORAGE`** — Azure Portal → *Storage account* → *Access keys* (apenas se usar o serviço `:microsoft`).

## Estrutura

- `app/` — controllers, models, views, mailers (multi-tenant por `Company`/subdomínio)
- `db/migrate/` — migrations (schema em `db/schema.rb`)
- `spec/` / `test/` — testes
- `Dockerfile` (produção) e `Dockerfile.dev` + `docker-compose.yml` (desenvolvimento)
