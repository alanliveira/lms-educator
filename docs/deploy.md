# Deploy com Docker

Como configurar o **Docker** e o **Docker Compose** para rodar o Educator LMS
em qualquer máquina — local, servidor ou CI.

Para desenvolvimento com Supabase local, o passo a passo completo está em
[`development.md`](development.md). Este documento trata só da parte de Docker.

## Pré-requisitos

| Ferramenta | Versão mínima | Verificação |
|---|---|---|
| Docker Engine (ou Docker Desktop) | 20.10+ | `docker info` |
| Docker Compose | v2 | `docker compose version` |

O projeto usa apenas `docker-compose.yml` (Compose V2, sintaxe `docker compose`,
sem hífen). O `Dockerfile` é o de produção e é o mesmo usado pelo compose.

## 1. Criar o `.env` (obrigatório)

**O `.env` é obrigatório para o compose**: ele é a única fonte das variáveis
(`${...}` são interpolidas a partir dele). Sem o arquivo, o compose avisa
`variable is not set` e o valor vira string vazia.

```bash
cp .env.sample .env
```

Depois ajuste o que for preciso. Chaves que o compose usa diretamente:

| Chave | Onde é usada | Obrigatória | Exemplo |
|---|---|---|---|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | serviço `db` (container Postgres) | Sim | `postgres` / `postgres` / `educator_lms_development` |
| `POSTGRES_PORT` | porta publicada do Postgres no host | Não (`5432`) | `5432` |
| `DATABASE_URL` | app (sobrescrita para `...@db:5432` dentro da rede) | Sim | `postgres://postgres:postgres@127.0.0.1:5432` |
| `EMAIL_ADMINISTRATION_SYSTEM` | `env_file` (runtime) **e** `build.args` | Sim | `no-reply@seudominio.com` |
| `SUPABASE_STORAGE_ENDPOINT` / `SUPABASE_KEY` / `SUPABASE_KEY_SECRET` / `SUPABASE_STORAGE_REGION` | `build.args` (e runtime em produção) | Sim (para buildar) | o `.env.sample` traz o Supabase local; produção usa os valores do projeto hospedado |
| `EMAIL_HOST`, `PORT`, `RAILS_ENV`, `REDIS_URL`, ... | `env_file` (runtime) | Sim | ver `.env.sample` |

> O `.env.sample` já traz defaults para as chaves do compose, então
> `cp .env.sample .env` funciona sem nenhum ajuste extra.

## 2. Validar a configuração: `docker compose config`

Sempre rode **antes** do build ou do `up`:

```bash
docker compose config
```

O comando expande todos os `${...}` a partir do `.env` e imprime a
configuração final que será usada — é a forma rápida de conferir se "está
tudo ok":

- **sem warnings** → todas as variáveis foram encontradas no `.env`;
- warning `The "X" variable is not set. Defaulting to a blank string.` →
  falta a chave `X` no `.env`: crie o arquivo (`cp .env.sample .env`) ou
  preencha a chave;
- confira especialmente `build.args` (o `assets:precompile` precisa deles),
  `DATABASE_URL` e as credenciais do `db`.

Versão curta, só o que interessa:

```bash
docker compose config | grep -E "args:|DATABASE_URL|POSTGRES_USER"
```

## 3. Build da imagem

```bash
docker compose build
```

Sempre via **compose**, nunca `docker build .` direto: só o compose entrega os
`build.args` (variáveis de build vindas do `.env`) ao `Dockerfile`.

O que o build faz (multi-stage, `Dockerfile`):

1. **build** — instala pacotes de sistema (`libpq-dev`, `libvips`,
   `libyaml-dev`...), Node/yarn, gems (`bundle install`), node modules e
   pré-compila os assets com `SECRET_KEY_BASE_DUMMY=1`. Nesse ponto a app sobe
   em `production` com eager loading, por isso os `ARG`
   `EMAIL_ADMINISTRATION_SYSTEM`, `SUPABASE_STORAGE_ENDPOINT`, `SUPABASE_KEY`
   e `SUPABASE_KEY_SECRET` precisam existir;
2. **final** — só o runtime: gems, código, assets e o usuário `rails`
   (não-root). Node/yarn **não** entram na imagem final.

Para reconstruir do zero (ex.: mudou o `Gemfile.lock` e o cache não resolve):

```bash
docker compose build --no-cache
```

## 4. Subir a stack

```bash
docker compose up -d
docker compose ps      # db: healthy, web: running
docker compose logs -f web
```

O serviço `web` espera o `db` ficar `healthy` (`pg_isready`), roda
`bin/rails db:prepare` (cria/carrega o schema) e sobe o servidor em `0.0.0.0:3000`.

Na primeira subida o setup inicial aparece em `http://localhost:3000` (redireciona
para o subdomínio `admin` — ver
[Primeiro acesso](development.md#6-primeiro-acesso-setup-inicial)).

## 5. Comandos úteis

| Comando | O que faz |
|---|---|
| `docker compose up -d` | sobe `db` + `web` em background |
| `docker compose up -d db` | só o Postgres (alternativa ao Supabase local) |
| `docker compose build` | reconstrói a imagem |
| `docker compose down` | para e remove os containers (o volume do banco fica) |
| `docker compose down -v` | idem **apagando** os volumes (banco perdido) |
| `docker compose logs -f web` | logs da aplicação |
| `docker compose exec web bin/rails console` | console Rails no container |
| `docker compose exec db psql -U postgres -d educator_lms_development` | psql direto |
| `docker compose restart web` | reinicia só a app |

## 6. De onde vem cada variável

| Mecanismo | Onde está | O que faz |
|---|---|---|
| `${VAR}` (interpolação) | `docker-compose.yml` | lê o `.env` **no host**, na hora de montar o compose (build args, portas, credenciais do `db`) |
| `env_file:` | serviço `web` | injeta **todas** as chaves do `.env` como variáveis do container |
| `environment:` | serviço `web` | sobrescreve pontualmente — é o caso do `DATABASE_URL` (`...@db:5432`), porque dentro da rede o host do Postgres é `db` |
| `ARG` | `Dockerfile` | variáveis de **build**, recebidas via `build.args`; não persistem na imagem final |

Precedência dentro do container: `environment` > `env_file` > `ENV` da imagem.
Como o `.env` é montado junto com o código (volume `.:/rails`), o `dotenv-rails`
também o lê — mas ele **não** sobrescreve variáveis já definidas, então o
compose continua mandando.

## 7. Portas

| Serviço | Porta no host | Porta no container |
|---|---|---|
| `web` | `3000` | `3000` (respeita `PORT`) |
| `db` | `POSTGRES_PORT` (`5432`) | `5432` |

> Não rode `bin/dev` (host) e `docker compose up` ao mesmo tempo: ambos
> publicam a porta `3000`.

## 8. Variáveis de produção

A mesma imagem serve para produção; o que muda são as variáveis, definidas no
provedor (Render, servidor, etc.) — **não** no `.env` (que é local e ignorado
pelo Git):

| Variável | Papel |
|---|---|
| `RAILS_MASTER_KEY` ou `SECRET_KEY_BASE` | credentials / segredo da app (obrigatória) |
| `EMAIL_ADMINISTRATION_SYSTEM`, `EMAIL_HOST`, `RESEND_API_KEY` | e-mails (Resend) |
| `SUPABASE_STORAGE_ENDPOINT`, `SUPABASE_KEY`, `SUPABASE_KEY_SECRET`, `SUPABASE_STORAGE_REGION` | Active Storage `:supabase` (bucket `contents-class`; região `sa-east-1`) |
| `REDIS_URL` | Action Cable (produção) |
| `DATABASE_URL` | banco **com** o nome do banco (como o provedor entrega) |

Atenção: `EMAIL_ADMINISTRATION_SYSTEM` e as três chaves `SUPABASE_*` também são
necessárias **no build** (o `assets:precompile` sobe a app em produção). No
Render, cadastre-as em *Environment → Build*; localmente valem os placeholders
do `.env.sample`.

## 9. Troubleshooting

**`docker compose config` avisa `The "X" variable is not set`**
: Falta a chave `X` no `.env`. Crie-o com `cp .env.sample .env` (as chaves do
  compose já vêm preenchidas no modelo) ou preencha a que faltar.

**`error getting credentials - err: exit status 1` no build/pull**
: O `~/.docker/config.json` tem `"credsStore": "desktop.exe"` e esse helper não
  roda no ambiente (erro WSL `UtilAcceptVsock`), derrubando **todo** pull do
  registry — inclusive o do frontend `docker/dockerfile:1`. Remova a chave
  `"credsStore"` (não há credencial salva nele).

**`An error occurred while installing psych` / `yaml.h not found`**
: Faltam os headers do libyaml na imagem `ruby:*-slim`. O `Dockerfile` já
  instala `libyaml-dev` — se foi removido, recoloque.

**Build falha com `key not found: "EMAIL_ADMINISTRATION_SYSTEM"` ou
`expected :endpoint to be a HTTP or HTTPS endpoint`**
: Os `build.args` não chegaram — você usou `docker build .` em vez de
  `docker compose build`, ou o `.env` está sem essas chaves (item 2).

**`PG::ObjectInUse` no `db:drop`**
: O container do Postgres está conectado. `docker compose down` antes do drop.

**Aplicação sem CSS/JS no container**
: A imagem final não tem Node. Rode `yarn build` (ou `bin/dev`) no host — os
  assets são servidos de `app/assets/builds` via volume.

## 10. Segurança

- `.env` é ignorado pelo Git e pelo `.dockerignore` (`/.env*`) — **nunca**
  entra na imagem nem no repositório.
- `config/master.key` também está no `.dockerignore`.
- Os placeholders de build não são gravados na imagem final (ficam só no stage
  de build), e em produção os valores reais vêm do provedor.
- O container roda como usuário `rails` (não-root).
