# Educator LMS

Plataforma de ensino à distância (LMS) **multi-tenant** para empresas:
cursos, turmas, acompanhamento de progresso e **certificados com validação
pública** — cada empresa no seu próprio subdomínio.

Feito em **Rails 8 + Hotwire (Turbo/Stream) + Tailwind**, autenticação por
sessão com papéis, e-mails via Resend e storage S3 do Supabase.

## O que a plataforma faz

- **Multi-tenancy por subdomínio** — cada empresa é um tenant
  (`acme.seuapp.com.br`), com dados, usuários e visualização isolados. O
  subdomínio `admin` é o tenant principal: recebe o setup inicial e hospeda a
  empresa padrão do sistema (`Company.default`).
- **Cursos e turmas** — cursos globais com descrição e carga horária, divididos
  em turmas/aulas; cada empresa só enxerga os cursos **liberados** para ela.
- **Progresso dos alunos** — conclusão de aula por aula
  (`course_class_completions`) e cálculo de 100% do curso por usuário.
- **Certificados com verificação** — ao concluir todas as aulas o aluno baixa
  um PDF com **código de verificação**; qualquer pessoa valida o certificado em
  `GET /certificates/<código>`, sem login. O layout do certificado é
  configurável por curso (elementos posicionados no PDF).
- **Papéis (Rolify)** — `admin` (gerencia tudo), `company` (gestor da empresa:
  usuários e visibilidade de cursos) e `student` (aluno).
- **Usuários e acesso** — cadastro com senha forte, verificação de e-mail,
  recuperação de senha, contas ativas/inativas, soft delete, sessões ativas e
  histórico de ações.
- **Identidade por e-mail** — verificação de e-mail, reset de senha e página de
  contato para domínio não suportado (`wrong_domain`), tudo via Resend.
- **Storage de arquivos** — Active Storage no bucket S3 privado
  `contents-class` do Supabase (logos, anexos), também em development com o
  Supabase local.

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Ruby **3.4.4** / Rails **8** (Hotwire, Turbo, Action Text, Active Storage) |
| Front-end | Tailwind CSS + webpack (`app/assets/builds`), importmap-free, yarn |
| Banco | PostgreSQL **16** (Supabase local em dev) |
| Cache/cable | Redis (`REDIS_URL`) |
| E-mail | Resend (SMTP/API) — dev usa MailDev |
| Storage | Supabase S3 (`contents-class`) |
| Testes | RSpec + Minitest, RuboCop |
| Deploy | Docker multi-stage + Docker Compose |

## Subindo localmente

```bash
mise install                      # versões do .tool-versions
cp .env.sample .env               # variáveis (ver docs/environment.md)
bundle install && yarn install
supabase start                    # Postgres + storage locais (ou docker compose up -d db)
docker compose config             # valida o .env
bin/rails db:prepare
yarn build && yarn build:css
bin/dev                           # server + assets + maildev (porta 3000)
```

Com o banco vazio a raiz redireciona para `admin.localhost:3000/setup/new`
(primeiro acesso). Testes e lint:

```bash
bundle exec rspec          # ou bin/rails test
bundle exec rubocop
```

## Documentação

| Documento | O que cobre |
|---|---|
| [docs/development.md](docs/development.md) | Setup de desenvolvimento na máquina: dependências, `.env`, Supabase local, storage, subir a app, testes e troubleshooting |
| [docs/deploy.md](docs/deploy.md) | Docker/Compose do zero: `.env` obrigatório, `docker compose config`, build, subir a stack, variáveis de produção e segurança |
| [docs/environment.md](docs/environment.md) | Referência de **todas as variáveis de ambiente**: o que é obrigatório, quem lê cada uma e onde obter os valores |
| [docs/initial_setup.md](docs/initial_setup.md) | **Configurações iniciais no site**: setup do primeiro tenant, papéis, empresas, usuários, cursos, turmas e certificados |

## Estrutura do projeto

```
app/
  controllers/    multi-tenant por subdomínio (setup, companies, courses, users...)
  models/         Company, Course, CourseClass, Certificate, User, Role...
  views/          Hotwire/Tailwind (app/assets/builds via yarn build)
  mailers/        UserMailer, WrongDomainMailer (Resend)
app/services/     Setup::CreateService, CourseCompletionService, PDF do certificado
config/           database.yml (nome por ambiente), storage.yml (:supabase/:local)
db/               schema.rb (19 tabelas), migrations, seeds (vazio por design)
docs/             guias desta pasta
Dockerfile        imagem de produção (multi-stage), usada também pelo compose
docker-compose.yml  lê 100% do .env — nada digitado no arquivo
.env.sample       modelo das variáveis de ambiente
```

## Licença

Privada — todos os direitos reservados.
