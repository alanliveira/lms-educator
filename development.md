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
DATABASE_URL=postgres://postgres:postgres@127.0.0.1:54422/educator_lms_development
TEST_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:54422/educator_lms_test
RAILS_ENV=development
RAILS_DEVELOPMENT_HOST=localhost:3000
PORT=3000
REDIS_URL=redis://localhost:6379/1
EMAIL_ADMINISTRATION_SYSTEM=admin@example.test
EMAIL_HOST=localhost:3000
COMPANY_DEFAULT_ID=1
```

| Variável | Obrigatória em dev | Observação |
|---|---|---|
| `DATABASE_URL` / `TEST_DATABASE_URL` | Sim | apontam para o Postgres do Supabase local (porta `54422`) |
| `RAILS_ENV` | Sim | `development` |
| `PORT` / `RAILS_DEVELOPMENT_HOST` | Sim | `3000` (o default do código tem um typo: `localhist:3000`) |
| `EMAIL_HOST` | Sim | usado nos links dos e-mails → `localhost:3000` |
| `EMAIL_ADMINISTRATION_SYSTEM` | Sim | remetente padrão (não precisa ser real em dev) |
| `COMPANY_DEFAULT_ID` | Sim* | `1` após criar a empresa na tela `/setup` (o DB começa vazio) |
| `REDIS_URL` | Sim | em development o Action Cable usa `async`, mas a variável é referenciada |
| `RESEND_API_KEY` | Não | deixe **fora do arquivo**; só é preciso para disparar e-mails reais |
| `RAILS_MASTER_KEY` | Não | só exigida em produção (não existe `config/master.key` no repo) |
| `SUPABASE_*` | Não | só usadas em produção (`config.active_storage.service = :supabase`) |

> **Nunca commite o `.env`** — já está no `.gitignore` (`/.env*`).

## 2. Subir o Supabase local (banco de dados)

O projeto usa a **stack local do Supabase** como Postgres de desenvolvimento
(diretório `supabase/` versionado com o `config.toml`).

```bash
supabase init     # só na primeira vez; cria supabase/config.toml
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

O `supabase/config.toml` deste repositório usa a faixa **544xx** em vez das
portas padrão da CLI (54320–54329), porque faixas como **53768–54352 são
bloqueadas pelo Docker nesta máquina** (`Error ... /forwards/expose returned
unexpected status: 500` ao publicar a porta). Portas mapeadas:

| Serviço | Porta |
|---|---|
| Postgres | `54422` (shadow: `54420`) |
| API / Kong (REST, Storage S3, Auth) | `54421` |
| Studio | `54423` |
| Mailpit (e-mail local) | `54424` |
| Pooler | `54429` |
| Analytics | `54427` |

Se a porta padrão funcionar na sua máquina, pode reverter para 543xx — mas
atualize também o `DATABASE_URL`/`TEST_DATABASE_URL` do `.env`.

> Em outra máquina/CI, o equivalente sem Supabase é
> `docker compose up -d db` (Postgres 16 em `localhost:5432`, ver
> `docker-compose.yml`) — nesse caso ajuste `DATABASE_URL` para
> `postgres://postgres:postgres@localhost:5432/educator_lms_development`.

## 3. Preparar o banco

```bash
bin/rails db:prepare
```

Cria o database `educator_lms_development` e carrega o schema (`db/schema.rb`,
19 tabelas). O `db/seeds.rb` é vazio: a **empresa padrão é criada pela própria
aplicação**, na primeira visita (`/setup/new`) — depois disso use o id real da
empresa no `COMPANY_DEFAULT_ID` (`bin/rails runner 'puts Company.first.id'`).

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
# → 302 para /setup/new e, em seguida, 200 "Portal educacional"
```

Abra `http://localhost:3000`, faça o setup inicial (empresa/usuário) e use
`http://localhost:1080` para inspecionar os e-mails enviados.

## Testes e lint

```bash
bundle exec rspec          # ou bin/rails test
bundle exec rubocop
```

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

**Erro de host (`Blocked hosts: ...`)**
: `RAILS_DEVELOPMENT_HOST` precisa bater com o host acessado (`localhost:3000`).

**E-mails não chegam / `Resend` com chave vazia**
: Esperado em dev sem `RESEND_API_KEY` — use o MailDev (`localhost:1080`),
  que captura tudo o que sai na porta 1025.
