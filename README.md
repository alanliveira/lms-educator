# Educator LMS

LMS multi-tenant (Rails 8 + Hotwire + Tailwind) com autenticação por subdomínio, cursos, turmas, certificados e e-mails via Resend.

## Pré-requisitos

- Ruby **3.4.4** / Node **22.1.0** (recomendado via [`mise`](https://mise.jdx.dev) — ver `.tool-versions`)
- Postgres **16** e **Redis** (ou use o `docker-compose.yml`, que sobe o Postgres)
- `yarn` e `bundler`

## Setup local

> Passo a passo detalhado (dependências, `.env`, Supabase local, troubleshooting): [`development.md`](development.md).
> Deploy com Docker / Docker Compose (`.env`, `docker compose config`, build e produção): [`deploy.md`](deploy.md).

```bash
mise install                      # instala versões do .tool-versions
cp .env.sample .env               # e preencha as variáveis (ver tabela abaixo)
bundle install
yarn install
docker compose config             # valida o .env (o compose interpola ${...} dele)
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
| `DATABASE_URL` | Sim | Conexão Postgres **sem o nome do banco** (o `config/database.yml` define o nome por ambiente). Local: `postgres://postgres:postgres@localhost:5432` |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` / `POSTGRES_PORT` | Não | Só para o `docker-compose.yml` (serviço `db`); defaults `postgres` / `postgres` / `educator_lms_development` / `5432` |
| `RAILS_ENV` | Não | `development` / `test` / `production` (padrão: development) |
| `RAILS_MASTER_KEY` | Em produção | Descriptografa `config/credentials.yml.enc` |
| `REDIS_URL` | Sim | Redis para Action Cable (`config/cable.yml`) |
| `RESEND_API_KEY` | Sim | Chave de API do Resend (envio de e-mail) |
| `EMAIL_ADMINISTRATION_SYSTEM` | Sim | Remetente padrão dos e-mails (ex.: `no-reply@seudominio.com`) |
| `EMAIL_HOST` | Sim | Host usado nos links dos e-mails (ex.: `educator.app.br`, `localhost:3000`) |
| `SUPABASE_STORAGE_ENDPOINT` | Em produção | Endpoint S3 do Supabase (Active Storage `:supabase`) |
| `SUPABASE_KEY` | Em produção | Access key ID do S3 do Supabase |
| `SUPABASE_KEY_SECRET` | Em produção | Secret access key do S3 do Supabase |
| `WEB_CONCURRENCY` | Não | Workers do Puma em produção (padrão: nº de CPUs) |
| `RAILS_LOG_LEVEL` | Não | `info` / `debug` (padrão: `info`) |
| `RAILS_MAX_THREADS` / `RAILS_MIN_THREADS` | Não | Threads do Puma (padrão: `5`) |
| `RAILS_DEVELOPMENT_HOST` | Não | Host liberado em development (padrão: `localhost:3000`) |
| `PORT` | Não | Porta do servidor (padrão: `3000`) |
| `AZURE_ACTIVE_STORAGE` | Não | Só se usar o serviço `:microsoft` — não é o default |

### Como obter cada variável

- **`DATABASE_URL`** — Local: use o Postgres do `docker compose up -d db` (credenciais em `.env`: `POSTGRES_USER` / `POSTGRES_PASSWORD`) e **remova o nome do banco** do fim da URL. Produção: painel do Render → *Databases* → *Connection strings* → *External* (nessa use a URL como ela vem, com o banco).
- **`POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` / `POSTGRES_PORT`** — Só usados pelo `docker-compose.yml` (serviço `db`). Use os mesmos valores do `DATABASE_URL` local; o default é `postgres` / `postgres` / `educator_lms_development` / `5432`.
- **`RAILS_MASTER_KEY`** — Chave que descriptografa `config/credentials.yml.enc` (o `config/master.key` é ignorado pelo Git). Se você já tem o arquivo `config/master.key` localmente, copie o valor. Senão, em uma cópia do projeto que tenha a chave: `bin/rails credentials:show`. **Atenção:** sem essa chave os credentials não podem ser recuperados — guarde em um cofre.
- **`RESEND_API_KEY`** — [resend.com](https://resend.com) → *API Keys* → *Create Key*.
- **`EMAIL_ADMINISTRATION_SYSTEM`** — No Resend: *Domains* → adicionar e verificar o domínio do remetente; o endereço precisa pertencer a um domínio verificado.
- **`EMAIL_HOST`** — Domínio público onde a app roda (produção: `educator.app.br` / `aprenda.seetech.com.br`; local: `localhost:3000`).
- **`SUPABASE_*`** — Supabase Dashboard → *Project Settings* → *Storage* → *S3 API* → *Create new credentials*. O endpoint tem o formato `https://<project-ref>.storage.supabase.co/storage/v1/s3`. O bucket usado é `contents-class` (`config/storage.yml`).
- **`REDIS_URL`** — Local: `redis://localhost:6379/1`. Produção: Upstash Redis, Render Redis ou similar.
- **`AZURE_ACTIVE_STORAGE`** — Azure Portal → *Storage account* → *Access keys* (apenas se usar o serviço `:microsoft`).

## Estrutura

- `app/` — controllers, models, views, mailers (multi-tenant por `Company`/subdomínio)
- `db/migrate/` — migrations (schema em `db/schema.rb`)
- `spec/` / `test/` — testes
- `Dockerfile` (produção; também usado pelo `docker-compose.yml`) e `docker-compose.yml`
