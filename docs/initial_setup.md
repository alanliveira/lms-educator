# Configurações iniciais do site

O que fazer **depois que a aplicação está no ar** — primeiro acesso, criação de
empresas, usuários, cursos e certificados.

> Este documento **não** cobre como subir a aplicação: para isso veja
> [development.md](development.md) (máquina local) ou
> [deploy.md](deploy.md) (Docker/produção).

## O que é o multi-tenancy

Cada **empresa** (tenant) vive no seu próprio subdomínio:
`<subdominio>.<dominio>` (ex.: `acme.localhost:3000` ou `acme.seuapp.com.br`).
Dados, usuários e visualização são separados por empresa — o tenant corrente é
resolvido a partir do host (`ApplicationController#tenant_subdomain`).

Existe um tenant especial: **`admin`** (`Company::DEFAULT_SUBDOMAIN`). É ele que:

- recebe o setup inicial (quando o banco está vazio, qualquer host redireciona
  para `admin.<host>/setup/new`);
- hospeda a empresa padrão do sistema, usada como fallback nos e-mails e nas
  telas — no código é `Company.default` (**não** existe variável de ambiente
  para isso).

## 1. Setup inicial (banco vazio)

1. Acesse a raiz do domínio. Com o banco vazio a plataforma redireciona para
   **`http://admin.<dominio>/setup/new`**.
2. Preencha:

   | Bloco | Campos |
   |---|---|
   | **Empresa** | nome, nome fantasia, CNPJ, endereço, **logo** (opcional — usado na navbar e na tela de login) |
   | **Usuário administrador** | nome completo, departamento, e-mail, senha e confirmação |

3. Clique em *Criar ambiente*. O POST acontece em `admin.<dominio>` e o
   redirect de sucesso é same-origin para a tela de **login**.
4. Entre com o e-mail e a senha do administrador.

O que o setup cria (`Setup::CreateService`):

- a empresa com subdomínio fixo **`admin`** — ela é a empresa padrão
  (`Company.default`);
- o usuário administrador já **ativo e verificado**, com papel **`admin`**
  (o papel `student` é removido) e marcação de *owner* na empresa.

### Regra de senha

Mínimo **8** e máximo **20** caracteres, contendo letras, números e **pelo
menos um caractere especial ou uma letra maiúscula**.

### Subdomínio não resolvendo no navegador?

Navegadores modernos resolvem `*.localhost` para `127.0.0.1` sem configuração
(convenção da RFC 6761). Se não resolver, adicione `127.0.0.1 admin.localhost`
ao `/etc/hosts` ou use um domínio wildcard (ex.: `admin.lvh.me`).

## 2. Papéis e permissões

Papéis (Rolify) definidos em `Users::UpdateService::ROLES` — cada usuário tem
**um** papel por empresa:

| Papel | O que pode |
|---|---|
| **`admin`** | tudo: gerencia cursos, turmas, certificados, empresas e todos os usuários |
| **`company`** (gestor da empresa) | vê e gerencia os **usuários `student` da própria empresa** e alterna a visibilidade dos cursos liberados para ela |
| **`student`** | vê os cursos liberados para a sua empresa, conclui aulas e baixa certificados |

A navbar mostra o que o papel atual pode ver: `Usuários` e `Sessões` ficam
ocultos para `student`; `Empresas` só aparece para `admin`.

## 3. Usuários

**Admin → Usuários → Novo usuário**

- Campos: nome completo, departamento, e-mail, senha, papel e empresa.
- **`ativo`** — usuário inativo não entra; quem cria pode marcar o status
  (admin gestora de empresa também pode alterar o `ativo` de seus `student`).
- **`verified`** — verificação de e-mail: o usuário recebe um link de
  verificação (token de 1 dia). Alterar o e-mail zera a verificação.
- Recuperação de senha: link válido por **20 minutos** (`identity/password_reset`).
- Usuários são exclusão lógica (`deleted_at`), nunca remoção física.

## 4. Empresas (tenants)

**Admin → Empresas** (só visível para o papel `admin`)

1. *Nova empresa* — preencha os dados e informe o **subdomínio** (é por ele que
   os usuários acessam: `<subdominio>.<dominio>`).
2. Na página da empresa: **editar**, **remover** (soft delete) e **liberar
   cursos**:
   - *Adicionar curso* — associa o curso à empresa;
   - *Acessar / Remover* — liga/desliga a visibilidade
     (`company_courses.can_be_viewed`) do curso para aquela empresa.
3. Cada empresa tem um dono (`company_users.owner`) — normalmente o usuário que
   a criou.

## 5. Cursos e turmas

**Cursos** (menu *Cursos*):

- **Criar/editar curso** (somente `admin`): nome, descrição e **carga horária**
  (horas).
- Cursos são globais; cada empresa enxerga apenas os que foram **liberados**
  para ela (item 4).

**Turmas** (dentro de cada curso, somente `admin`):

- Criar turma: nome e descrição.
- O aluno **conclui uma aula** com o botão de conclusão → a app marca
  `course_class_completions` e responde se o **certificado ficou pronto**
  (todas as aulas do curso concluídas).

**Progresso**: `CourseCompletionService` calcula se o usuário concluiu 100% das
turmas do curso — só então o download do certificado é liberado.

## 6. Certificados

**Curso → Certificado → Editar** (somente `admin`):

- O template é configurável: elementos posicionados em porcentagem no PDF
  (`certificate.elements`, editados via `elements_json`) — posição X/Y, fonte,
  cor etc., incluindo o **código de verificação**.
- **Download** (aluno, com todas as aulas concluídas): gera o PDF
  (`CertificatePdfRenderer`) com um **código de verificação** novo por emissão
  (`certificate_issuances`) e devolve o arquivo `certificado-<curso>.pdf`.
- **Validação pública**: qualquer pessoa consulta
  `GET /certificates/<verification_code>` — sem login — para conferir a
  autenticidade do certificado.

## 7. Sessões e auditoria

- **Sessões** (menu *Sessões*): sessões ativas do usuário (IP, user agent,
  criadas em `sign_in`), com opção de encerrar.
- **Histórico** (`histories`): ações relevantes registradas por usuário.

## 8. E-mails

| E-mail | Quando | Onde verificar |
|---|---|---|
| Verificação de e-mail | cadastro / troca de e-mail | Resend (produção) ou MailDev `localhost:1080` (dev) |
| Recuperação de senha | "Esqueci a senha" | idem |
| Contato de domínio errado | formulário de `wrong_domain` | chega em `EMAIL_ADMINISTRATION_SYSTEM` |

Produção requer `RESEND_API_KEY` + domínio verificado e
`EMAIL_ADMINISTRATION_SYSTEM`/`EMAIL_HOST` corretos — ver
[environment.md](environment.md#e-mail-resend).

## Checklist do primeiro tenant

- [ ] Setup inicial feito no subdomínio `admin` e login realizado;
- [ ] Logo da empresa enviada (aparece na navbar e no login);
- [ ] Cursos criados com carga horária e turmas;
- [ ] Cursos liberados para a empresa (Empresas → *Adicionar curso*);
- [ ] Usuários cadastrados com papel e empresa corretos e marcados como ativos;
- [ ] Certificado do curso editado (layout + código de verificação);
- [ ] Teste: aluno conclui todas as aulas → baixa o PDF → valida em
      `/certificates/<código>`.
