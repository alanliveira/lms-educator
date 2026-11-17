# Setup de desenvolvimento (máquina local)

Passo a passo para subir o **Educator LMS** em uma máquina de desenvolvimento do zero.

## Pré-requisitos

| Ferramenta | Versão | Como instalar |
|---|---|---|
| Ruby | **3.4.4** | [`mise`](https://mise.jdx.dev/) (`mise install`, lê `.tool-versions` / `.ruby-version`) |
| Node | **22.1.0** | idem (`mise install`) |
| Yarn | 1.x | `npm install -g yarn` |
| Bundler | 2.6+ | `gem install bundler` |
| Docker | qualquer | necessário para o Supabase local (Postgres + Storage) |
| Supabase CLI | 3.x | `npm i -g supabase` ou via `mise`/`brew` |
| overmind | última | instalado automaticamente pelo `bin/dev` |
| maildev | última | instalado automaticamente pelo `bin/dev` |

Verificação rápida das dependências:

```bash
ruby -v          # deve ser 3.4.4
node -v          # deve ser 22.1.0
yarn -v
bundle -v
supabase --version
docker info      # daemon do Docker rodando
```

Instale as dependências de código:

```bash
mise install      # aponta Ruby/Node para as versões do .tool-versions
bundle check      # ou: bundle install
yarn install
```

## 1. Criar o `.env`

```bash
cp .env.sample .env
```

Preencha apenas as variáveis necessárias em development (as demais **devem ficar
comentadas/removidas — chaves com valor vazio quebram o boot**, veja
[Troubleshooting](#troubleshooting)):

```env
DATABASE_URL=postgres://postgres:postgres@127.0.0.1:54422
RAILS_ENV=development
RAILS_DEVELOPMENT_HOST=localhost:3000
PORT=3000
REDIS_URL=redis://localhost:6379/1
EMAIL_ADMINISTRATION_SYSTEM=admin@example.test
EMAIL_HOST=localhost:3000
```

| Variável | Obrigatória em dev | Observação |
|---|---|---|
| `DATABASE_URL` | Sim | Postgres do Supabase local (porta `54422`), **sem o nome do banco** — o `config/database.yml` define `educator_lms_development` / `educator_lms_test` por ambiente (não existe `TEST_DATABASE_URL`) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` / `POSTGRES_PORT` | Não | só do `docker-compose.yml` (ver [Docker](#docker-alternativa-sem-supabase)) |
| `RAILS_ENV` | Sim | `development` |
| `PORT` / `RAILS_DEVELOPMENT_HOST` | Sim | `3000` (o default do código tem um typo: `localhist:3000`) |
| `EMAIL_HOST` | Sim | usado nos links dos e-mails → `localhost:3000` |
| `EMAIL_ADMINISTRATION_SYSTEM` | Sim | remetente padrão (não precisa ser real em dev) |
| `REDIS_URL` | Sim | em development o Action Cable usa `async`, mas a variável é referenciada |
| `RESEND_API_KEY` | Não | deixe **fora do arquivo**; só é preciso para disparar e-mails reais |
| `RAILS_MASTER_KEY` | Não | só exigida em produção (não existe `config/master.key` no repo) |
| `SUPABASE_*` | Não | só usadas em produção (`config.active_storage.service = :supabase`) |

> **Empresa padrão do sistema:** não existe variável de ambiente para isso
> (`COMPANY_DEFAULT_ID` foi removida). A empresa padrão é a criada no setup
> inicial — subdomínio `admin`, acessível por `Company.default`.

> **Nunca commite o `.env`** — já está no `.gitignore` (`/.env*`).

## 2. Subir o Supabase local (banco de dados)

O projeto usa a **stack local do Supabase** como Postgres de desenvolvimento
(diretório `supabase/`, **ignorado pelo Git** — cada máquina roda o `supabase init`
na primeira vez e pode ajustar as portas conforme sua máquina).

```bash
supabase init     # só na primeira vez; cria supabase/config.toml
# se `supabase start` reclamar de porta bloqueada, ajuste o config.toml
# para a faixa 544xx antes de continuar (ver "Portas locais" abaixo)
supabase start    # sobe Postgres, API/Kong, Studio, Mailpit etc.
```

Saída esperada (resumo):

```
DB_URL:   postgresql://postgres:postgres@127.0.0.1:54422/postgres
API_URL:  http://127.0.0.1:54421
STUDIO:   http://127.0.0.1:54423
MAILPIT:  http://127.0.0.1:54424
```

Comandos úteis:

```bash
supabase status   # portas e chaves locais
supabase stop     # parar a stack
supabase db reset # recriar o schema do zero
```

### Portas locais (importante)

O `supabase/config.toml` gerado pelo `supabase init` deve usar a faixa **544xx**
em vez das portas padrão da CLI (54320–54329), porque faixas como **53768–54352
são bloqueadas pelo Docker nesta máquina** (`Error ... /forwards/expose returned
unexpected status: 500` ao publicar a porta). Portas usadas aqui:

| Serviço | Porta |
|---|---|
| Postgres | `54422` (shadow: `54420`) |
| API / Kong (REST, Storage S3, Auth) | `54421` |
| Studio | `54423` |
| Mailpit (e-mail local) | `54424` |
| Pooler | `54429` |
| Analytics | `54427` |

Se a porta padrão funcionar na sua máquina, pode reverter para 543xx — mas
atualize também o `DATABASE_URL` do `.env` (**sem** o nome do banco: ele vem
do `config/database.yml`, por ambiente).

> Em outra máquina/CI, o equivalente sem Supabase é
> `docker compose up -d db` (Postgres 16 em `localhost:5432`, ver
> [Docker](#docker-alternativa-sem-supabase)) — nesse caso ajuste
> `DATABASE_URL` para `postgres://postgres:postgres@localhost:5432`.

### Storage (Active Storage)

Development usa **o mesmo storage de produção**: o serviço `:supabase`
(`config/storage.yml`), um bucket S3 privado chamado `contents-class` — só que
apontando para o Supabase local em vez do projeto hospedado.

Como funciona:

- **Ativação**: `config/environments/development.rb` usa `:supabase` quando
  `SUPABASE_STORAGE_ENDPOINT` está preenchido no `.env` e cai para o disco
  local (`:local`, pasta `storage/`) quando está vazio — dá para desenvolver
  sem Supabase.
- **Chaves**: pegue-as com `supabase status -o env` (mudam a cada `supabase
  start`!):

  ```bash
  supabase status -o env | grep -E "STORAGE_S3_URL|S3_PROTOCOL"
  # STORAGE_S3_URL="http://127.0.0.1:54421/storage/v1/s3"   ← SUPABASE_STORAGE_ENDPOINT
  # S3_PROTOCOL_ACCESS_KEY_ID=...                           ← SUPABASE_KEY
  # S3_PROTOCOL_ACCESS_KEY_SECRET=...                       ← SUPABASE_KEY_SECRET
  # S3_PROTOCOL_REGION="local"                              ← SUPABASE_STORAGE_REGION
  ```

- **Região**: o SigV4 inclui a região na assinatura — no Supabase local é
  `local`, em produção `sa-east-1` (`SUPABASE_STORAGE_REGION` no `.env`).
- **Bucket**: `contents-class` (privado) é declarado em `supabase/config.toml`
  e criado no `supabase start`. Em uma stack antiga (rodando antes da declaração
  existir), crie uma vez pela API:

  ```bash
  curl -X POST http://127.0.0.1:54421/storage/v1/bucket \
    -H "apikey: <SERVICE_ROLE_KEY>" -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
    -H "Content-Type: application/json" -d '{"name":"contents-class","public":false}'
  ```

- **Docker**: dentro do container `127.0.0.1` é o próprio container; o compose
  sobrescreve o endpoint para `http://host.docker.internal:54421/...` e adiciona
  `extra_hosts: host.docker.internal:host-gateway`.

### Docker (alternativa sem Supabase)

O `docker-compose.yml` lê **tudo do `.env`** — nenhuma variável está digitada
no compose. Passo a passo:

```bash
cp .env.sample .env      # 1. criar o .env (obrigatório: o compose interpola ${...} dele)
docker compose config     # 2. validar a configuração
docker compose build      # 3. build da imagem
docker compose up -d      # 4. subir db + web
```

**`docker compose config` é a checagem de sanidade** — rode sempre antes do
build ou do `up`. Ele expande os `${...}` a partir do `.env` e imprime o valor
final de cada variável; toda chave usada pelo compose e ausente (ou vazia) no
`.env` aparece como aviso:

```
level=warning msg="The "SUPABASE_KEY" variable is not set. Defaulting to a blank string."
```

Se aparecer algum warning, a variável vai virar string vazia — preencha o
`.env` (ou crie-o com `cp .env.sample .env`) antes de seguir.

Comandos úteis:

```bash
docker compose up -d        # db + web
docker compose up -d db     # só o Postgres
docker compose build        # reconstruir a imagem
docker compose down         # parar
```

- **`web`** recebe todas as chaves do `.env` via `env_file` e só sobrescreve
  `DATABASE_URL` (`...@db:5432`, porque dentro da rede o host do Postgres é
  `db`, não `127.0.0.1`) e `SUPABASE_STORAGE_ENDPOINT`
  (`http://host.docker.internal:54421/storage/v1/s3`, porque o Supabase local
  roda no host).
- **`db`** usa `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` e
  `POSTGRES_PORT` do `.env` — os mesmos valores do `DATABASE_URL`.
- **Build**: `docker compose build` entrega ao `Dockerfile` os `ARG` que o
  `assets:precompile` exige (`EMAIL_ADMINISTRATION_SYSTEM`,
  `SUPABASE_STORAGE_ENDPOINT`, `SUPABASE_KEY`, `SUPABASE_KEY_SECRET`), todos
  lidos do `.env` (o `.env.sample` já traz placeholders para o build local; em
  produção use os valores reais). Por isso o build é sempre via **compose**: um
  `docker build .` direto não passa esses args e falha no eager load.
- A imagem é a do `Dockerfile` (produção); o `RAILS_ENV=development` do `.env`
  sobrescreve o `RAILS_ENV=production` embutido na imagem.
- Os assets são servidos de `app/assets/builds`, então **rode `yarn build` (ou
  `bin/dev`) no host**: o container de runtime não tem Node/yarn. Por isso
  `Dockerfile.dev` foi removido — não existe mais imagem de dev separada.
- Não rode `bin/dev` e `docker compose up` ao mesmo tempo: ambos publicam a
  porta `3000`.

> Guia completo de Docker/Compose — build, variáveis de produção, comandos e
> troubleshooting: [`deploy.md`](deploy.md).

## 3. Preparar o banco

```bash
bin/rails db:prepare
```

Cria o database `educator_lms_development` e carrega o schema (`db/schema.rb`,
19 tabelas). O `db/seeds.rb` é vazio: a **empresa padrão do sistema é a criada
pelo setup inicial** (subdomínio `admin`, consultável com `Company.default`) —
não há variável de ambiente para configurar (ver
[Primeiro acesso](#6-primeiro-acesso-setup-inicial)).

## 4. Build dos assets

```bash
yarn build        # webpack  → app/assets/builds/application.js
yarn build:css    # tailwind → app/assets/builds/application.css
```

Os dois rodam de novo em modo watch quando você usa o `bin/dev`.

## 5. Subir a aplicação

```bash
bin/dev
```

O `bin/dev` instala `overmind` e `maildev` se faltarem e sobe o `Procfile.dev`:

| Processo | Comando | Porta |
|---|---|---|
| `web` | `rdbg` + `bin/rails s -b 0.0.0.0` | **3000** |
| `js` | `yarn build --watch` | — |
| `css` | `yarn build:css --watch` | — |
| `mail` | `maildev` | SMTP **1025**, UI **1080** |

Validação:

```bash
curl -i http://localhost:3000/
# → 302 Location: http://admin.localhost:3000/setup/new (banco vazio)

curl -i http://admin.localhost:3000/setup/new
# → 200 "Configuração inicial"
```

Use `http://localhost:1080` (MailDev) para inspecionar os e-mails enviados.

## 6. Primeiro acesso (setup inicial)

O setup inicial **só é servido pelo subdomínio `admin`** — essa é a regra do
fluxo (`ApplicationController#redirect_to_initial_setup`):

1. **Acesse `http://localhost:3000`**. Com o banco vazio a plataforma
   redireciona sozinha para **`http://admin.localhost:3000/setup/new`** (pode
   também digitar a URL direto). Qualquer host fora do subdomínio `admin`
   — inclusive `localhost:3000/setup/new` — cai nesse mesmo redirect.
2. **Preencha empresa + usuário administrador** e clique em *Criar ambiente*.
   O POST acontece em `admin.localhost` e o redirect de sucesso é
   **same-origin** para `http://admin.localhost:3000/sign_in` — por isso o
   Turbo consegue navegar e o aviso *"Empresa e usuário administrador criados
   com sucesso."* aparece na tela de login.
3. **Entre com o e-mail e a senha do dono** que você acabou de criar. Você
   estará no subdomínio `admin`, que é a empresa principal (subdomínio fixo
   `admin`, definido em `Setup::CreateService`).
4. **Demais tenants** entram por `<subdominio>.localhost:3000`
   (ex.: `acme.localhost:3000`); novas empresas são criadas pelo admin em
   *Empresas*.
5. **Empresa padrão do sistema**: a empresa criada neste setup é a padrão —
   usada como fallback nos e-mails e nas telas quando um registro não tem
   empresa própria. No código é `Company.default` (subdomínio `admin`); nenhuma
   variável de ambiente precisa ser configurada (`COMPANY_DEFAULT_ID` foi
   removida).

### Subdomínio `*.localhost` no navegador

Navegadores modernos resolvem `admin.localhost` para `127.0.0.1` sem
configuração nenhuma (convenção da RFC 6761). Se no seu ambiente não
resolver:

- adicione `127.0.0.1 admin.localhost` ao `/etc/hosts`, ou
- use um domínio wildcard que aponte para `127.0.0.1` (ex.: `admin.lvh.me`).

A aplicação reconhece o subdomínio em dois formatos (ver
`ApplicationController#tenant_subdomain`): `<sub>.localhost` e
`<sub>.<dominio>`.

### Refazer o setup do zero

O servidor precisa estar **parado**, senão o Postgres recusa o drop
(`PG::ObjectInUse: ... being accessed by other users`):

```bash
# pare o bin/dev (Ctrl+C no overmind) e então:
bin/rails db:drop db:create db:schema:load
bin/dev
```

## Testes e lint

```bash
bundle exec rspec          # ou bin/rails test
bundle exec rubocop
```

Não há variável de teste: o `config/database.yml` define o nome do banco de
cada ambiente (`educator_lms_development` / `educator_lms_test`) e a
`DATABASE_URL` do `.env` é usada **sem o nome do banco**.

> Por quê: o Rails mescla a `DATABASE_URL` por cima do `database.yml` do
> ambiente atual, e a URL vence a chave `database:`. Se ela tiver um nome
> (ex.: `.../educator_lms_development`), a suíte roda contra esse banco —
> ou seja, contra o de development. O `spec/rails_helper.rb` aborta nesse caso
> antes de qualquer spec tocar nos dados.

O database de testes é criado uma única vez:

```bash
RAILS_ENV=test bin/rails db:create
RAILS_ENV=test bin/rails db:schema:load
```

> Com `DATABASE_URL` definida, o `db:create` sozinho **não** cria o database
> de testes (comportamento padrão do Rails) — por isso o `db:schema:load`
> explícito acima.

## Troubleshooting

**Puma morre com `Kernel#Integer': invalid value for Integer(): ""`**
: O `.env` tem `WEB_CONCURRENCY=` (ou `RAILS_MAX_THREADS=`, `RAILS_MIN_THREADS=`) com
  valor vazio. O Puma faz `Integer(ENV["WEB_CONCURRENCY"])` e explode. Comente ou
  remova **toda chave sem valor** do `.env` — os defaults do Rails valem.

**`supabase start` falha com `/forwards/expose returned unexpected status: 500`**
: A porta está bloqueada no host. Teste com
  `docker run --rm -p 127.0.0.1:<porta>:80 nginx:alpine` e escolha uma porta livre
  (ver faixa 544xx acima).

**`Address already in use` / socket do overmind**
: `rm -f .overmind.sock` e rode `bin/dev` de novo.

**`PG::ConnectionBad` ou database inexistente**
: Confirme o Supabase no ar (`supabase status`) e rode `bin/rails db:prepare`.

**`PG::ObjectInUse: ... being accessed by other users` no `db:drop`**
: O servidor (`bin/dev`/Puma) está conectado ao banco. Pare o `bin/dev`
  (Ctrl+C no overmind) e rode o drop de novo.

**`docker compose build` falha com `error getting credentials - err: exit status 1`**
: O `~/.docker/config.json` tem `"credsStore": "desktop.exe"` e esse helper não
  roda neste ambiente (erro `WSL ... UtilAcceptVsock`), então **todo** pull do
  registry falha — inclusive o do frontend `docker/dockerfile:1`. Remova a
  chave `"credsStore"` do arquivo (não há credenciais salvas nele) e rode o
  build de novo.

**`An error occurred while installing psych` / `yaml.h not found` no build**
: A imagem `ruby:*-slim` não traz os headers do libyaml. O `Dockerfile` já
  instala `libyaml-dev` no stage de build — se você removeu, recoloque.

**Upload de imagem falha com `403 SignatureDoesNotMatch` (ou `AccessDenied`)**
: As chaves S3 mudam a cada `supabase start`. Rode `supabase status -o env` e
  atualize `SUPABASE_STORAGE_ENDPOINT`, `SUPABASE_KEY`, `SUPABASE_KEY_SECRET` e
  `SUPABASE_STORAGE_REGION` no `.env`. Se a região estiver errada, a assinatura
  SigV4 também não bate.

**Upload falha com `NoSuchBucket` (404) no bucket `contents-class`**
: O bucket não existe na sua stack local (criado antes de `supabase/config.toml`
  declará-lo). Crie pela API — ver [Storage (Active
  Storage)](#storage-active-storage).

**Testes abortam com `Specs would run against "..."`**
: A `DATABASE_URL` do `.env` tem o nome do banco no final. Remova a parte
  `/educator_lms_development` — vira `postgres://...@127.0.0.1:54422`
  (ver [Testes e lint](#testes-e-lint)).

**Testes falham com `connection to server ... port 5432` ou `database "educator_lms_test" does not exist`**
: O Supabase não está no ar (ver `supabase status`) ou o database de testes
  ainda não foi criado (ver [Testes e lint](#testes-e-lint)).

**`Blocked hosts: ...`**
: `RAILS_DEVELOPMENT_HOST` precisa bater com o host acessado (`localhost:3000`).

**E-mails não chegam / `Resend` com chave vazia**
: Esperado em dev sem `RESEND_API_KEY` — use o MailDev (`localhost:1080`),
  que captura tudo o que sai na porta 1025.
