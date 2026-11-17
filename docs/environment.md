# Variáveis de ambiente

Referência completa das variáveis do **Educator LMS**: onde cada uma é lida,
quem é obrigatória e onde obter o valor.

- **Modelo**: `.env.sample` (chaves com default só para o compose).
- **Local**: copie para `.env` — `cp .env.sample .env` (ignorado pelo Git,
  nunca commitado).
- **Produção**: defina no provedor (Render, servidor, CI) — o `.env` é local e
  **não** vai para lá.

> **Não existem** (removidas do projeto): `COMPANY_DEFAULT_ID` (a empresa
> padrão é a criada no setup inicial, consultável com `Company.default`) e
> `TEST_DATABASE_URL` (o nome do banco de testes vem do `config/database.yml`).

## Como as variáveis chegam à aplicação

| Mecanismo | Onde | Uso |
|---|---|---|
| `${VAR}` (interpolação) | `docker-compose.yml` | lê o `.env` no host na hora de montar o compose (build args, portas, credenciais do `db`) |
| `env_file:` | serviço `web` | injeta todas as chaves do `.env` no container |
| `environment:` | serviço `web` | sobrescreve pontualmente (`DATABASE_URL` → `...@db:5432`; `SUPABASE_STORAGE_ENDPOINT` → `host.docker.internal`) |
| `ARG` | `Dockerfile` | variáveis de **build**, entregues pelo `build.args` do compose; não persistem na imagem |

Validação rápida: `docker compose config` (ver [deploy](deploy.md#2-validar-a-configuração-docker-compose-config)).

## Banco de dados

| Variável | Obrigatória | Onde é lida | Descrição |
|---|---|---|---|
| `DATABASE_URL` | Sim | Rails (`config/database.yml`) | Conexão Postgres **sem o nome do banco** no fim: `postgres://USER:PASSWORD@HOST:PORT`. O nome (`educator_lms_development` / `_test` / `_production`) vem do `database.yml`. Local: `postgres://postgres:postgres@127.0.0.1:54422` (Supabase) |
| `POSTGRES_USER` | Compose | `docker-compose.yml` | usuário do container `db` (use o mesmo do `DATABASE_URL`) |
| `POSTGRES_PASSWORD` | Compose | `docker-compose.yml` | senha do container `db` |
| `POSTGRES_DB` | Compose | `docker-compose.yml` | database criado pelo container `db` (padrão `educator_lms_development`) |
| `POSTGRES_PORT` | Não (`5432`) | `docker-compose.yml` | porta do Postgres publicada no host |

> Por que `DATABASE_URL` não pode ter nome de banco: o Rails **mescla** a URL
> por cima do `database.yml` e ela vence a chave `database:`. Com nome, a suíte
> de testes roda contra o banco de development — o `spec/rails_helper.rb`
> aborta nesse caso antes de tocar em qualquer dado.

## Rails

| Variável | Obrigatória | Descrição |
|---|---|---|
| `RAILS_ENV` | Não (`development`) | `development` / `test` / `production` |
| `RAILS_MASTER_KEY` | Em produção | descriptografa `config/credentials.yml.enc` (não existe `config/master.key` no repo; em produção pode-se usar `SECRET_KEY_BASE` no lugar) |
| `SECRET_KEY_BASE` | Em produção* | alternativa ao master key para o segredo da app |
| `RAILS_LOG_LEVEL` | Não (`info`) | `debug` / `info` / `warn` / `error` / `fatal` |
| `RAILS_MAX_THREADS` | Não (`5`) | threads do Puma |
| `RAILS_MIN_THREADS` | Não (= `RAILS_MAX_THREADS`) | threads mínimas do Puma |
| `WEB_CONCURRENCY` | Não | workers do Puma em produção (padrão: nº de CPUs) |
| `PORT` | Não (`3000`) | porta do servidor |
| `RAILS_DEVELOPMENT_HOST` | Não | host liberado pelo `host_authorization` em development (ex.: `localhost:3000`) |

> **Chave sem valor quebra o boot**: `WEB_CONCURRENCY=` (ou
> `RAILS_MAX_THREADS=`, `RAILS_MIN_THREADS=`, `RAILS_LOG_LEVEL=`) vazio faz o
> Puma falhar com `Kernel#Integer': invalid value for Integer(): ""`. Comente
> ou remova a chave inteira — os defaults do Rails valem.

## Redis

| Variável | Obrigatória | Onde é lida | Descrição |
|---|---|---|---|
| `REDIS_URL` | Sim | `config/cable.yml` | Action Cable. Local: `redis://localhost:6379/1`; produção: Upstash/Render Redis |

## E-mail (Resend)

| Variável | Obrigatória | Onde é lida | Descrição |
|---|---|---|---|
| `RESEND_API_KEY` | Para enviar e-mails de verdade | `UserMailer` / Resend | chave de API do [resend.com](https://resend.com) (*API Keys*). Sem ela os e-mails falham em produção; em dev use o MailDev (`localhost:1080`) |
| `EMAIL_ADMINISTRATION_SYSTEM` | Sim | mailers **e** `build.args` | remetente padrão; o domínio precisa estar verificado no Resend (ex.: `no-reply@seudominio.com`) |
| `EMAIL_HOST` | Sim | mailers | host usado nos links dos e-mails (produção: domínio público; local: `localhost:3000`) |

## Storage (Active Storage → Supabase S3)

Serviço `:supabase` (`config/storage.yml`), bucket privado **`contents-class`**.
Em development, o `config/environments/development.rb` usa `:supabase` quando
`SUPABASE_STORAGE_ENDPOINT` está preenchido e cai para o disco (`:local`) quando
está vazio.

| Variável | Obrigatória | Descrição |
|---|---|---|
| `SUPABASE_STORAGE_ENDPOINT` | Sim (também é `build.arg`) | endpoint S3 com `/s3` no final. Local: `http://127.0.0.1:54421/storage/v1/s3`; produção: `https://<project-ref>.storage.supabase.co/storage/v1/s3`. No Docker o compose sobrescreve para `http://host.docker.internal:54421/storage/v1/s3` |
| `SUPABASE_KEY` | Sim (também é `build.arg`) | Access Key ID. Local: `supabase status -o env` → `S3_PROTOCOL_ACCESS_KEY_ID` (muda a cada `supabase start`); produção: Dashboard → *Project Settings → Storage → S3 API* |
| `SUPABASE_KEY_SECRET` | Sim (também é `build.arg`) | Secret Access Key. Local: `S3_PROTOCOL_ACCESS_KEY_SECRET`; produção: idem acima |
| `SUPABASE_STORAGE_REGION` | Não (`sa-east-1`) | região do SigV4 — **faz parte da assinatura**: local `local`, produção `sa-east-1` |
| `AZURE_ACTIVE_STORAGE` | Não | só se usar o serviço `:microsoft` (não é o default) |

Troubleshooting (`403 SignatureDoesNotMatch`, `NoSuchBucket`): ver
[development.md → Storage](development.md#storage-active-storage).

## Exemplos

### Development local (`.env`)

```env
DATABASE_URL=postgres://postgres:postgres@127.0.0.1:54422
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=educator_lms_development
POSTGRES_PORT=5432
RAILS_ENV=development
RAILS_DEVELOPMENT_HOST=localhost:3000
PORT=3000
REDIS_URL=redis://localhost:6379/1
EMAIL_ADMINISTRATION_SYSTEM=admin@example.test
EMAIL_HOST=localhost:3000
SUPABASE_STORAGE_ENDPOINT=http://127.0.0.1:54421/storage/v1/s3
SUPABASE_KEY=...
SUPABASE_KEY_SECRET=...
SUPABASE_STORAGE_REGION=local
```

`RESEND_API_KEY` e `RAILS_MASTER_KEY` ficam **fora** do arquivo em dev.

### Produção (variáveis do provedor)

| Variável | Valor |
|---|---|
| `RAILS_MASTER_KEY` ou `SECRET_KEY_BASE` | obrigatória (cofre/credenciais) |
| `DATABASE_URL` | do provedor — **com** o nome do banco (o do provedor é o de produção) |
| `RESEND_API_KEY`, `EMAIL_ADMINISTRATION_SYSTEM`, `EMAIL_HOST` | Resend com domínio verificado |
| `SUPABASE_STORAGE_ENDPOINT`, `SUPABASE_KEY`, `SUPABASE_KEY_SECRET`, `SUPABASE_STORAGE_REGION` (`sa-east-1`) | Supabase hospedado, bucket `contents-class` |
| `REDIS_URL` | Redis gerenciado |
| `POSTGRES_*`, `RAILS_DEVELOPMENT_HOST`, `PORT` | não usadas fora do compose local |

> `EMAIL_ADMINISTRATION_SYSTEM` e os `SUPABASE_*` também são necessários
> **no build** (o `assets:precompile` sobe a app em produção) — no Render,
> cadastre-as em *Environment → Build*.

Ver também: [deploy.md](deploy.md) (Docker/Compose) e
[development.md](development.md) (máquina local).
