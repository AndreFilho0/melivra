# Contribuindo para o Projeto

Obrigado por querer contribuir com este projeto! Para garantir um fluxo de trabalho organizado e limpo, siga as etapas abaixo cuidadosamente.

---
Recomendamos o uso do [asdf](https://asdf-vm.com/guide/getting-started.html) como gerenciador de versões para Elixir, Erlang e Node.js, a fim de facilitar a instalação e garantir compatibilidade entre ambientes.



## 1. Faça um Fork do Repositório

Clique em **Fork** no canto superior direito da página do repositório para criar uma cópia do projeto no seu GitHub.

---

## 2. Clone o Repositório Forkado

Depois de realizar o fork, clone o repositório na sua máquina local:

### Usando HTTPS:
```bash
git clone https://github.com/AndreFilho0/melivra.git
cd melivra
```

### Usando SSH:
```bash
git clone git@github.com:AndreFilho0/melivra.git
cd melivra
```

---

## 3. Sempre Crie uma Branch a Partir da develop

Antes de começar qualquer implementação, certifique-se de que está na branch develop e que ela está atualizada:

```bash
git checkout develop
git pull origin develop
```

Em seguida, crie uma nova branch com um nome descritivo do que será feito.

### Formato de nomes de branch

Use nomes claros que indiquem o propósito da branch. Exemplos:
- `feature/adicionar-login`
- `feature/cadastro-usuario`
- `bugfix/corrigir-erro-login`
- `hotfix/corrigir-build-producao`
- `chore/atualizar-dependencias`

### Criação da branch:
```bash
git checkout -b feature/adicionar-login
```

---

## 4. Faça Commits com Mensagens Descritivas

Cada commit deve explicar claramente o que foi feito. Exemplos de boas mensagens de commit:
- `feat: adiciona funcionalidade de login com token JWT`
- `fix: corrige redirecionamento após login`
- `chore: atualiza versão do React para 18.2.0`

Evite mensagens genéricas como `update`, `fix`, ou `ajustes`.

---

## 5. Abra um Pull Request (PR)

Depois de finalizar sua implementação:

1. Faça push da sua branch para o repositório remoto:
   ```bash
   git push origin feature/adicionar-login
   ```

2. Vá até o GitHub e abra um Pull Request (PR) da sua branch para a `develop`.

### O que incluir no PR

- Um título claro com o objetivo da alteração
- Uma descrição detalhada explicando o que foi feito, o porquê e, se necessário, como testar

### Exemplo de descrição:

```markdown
## O que foi feito
- Implementada tela de login
- Integração com API de autenticação
- Armazenamento de token no localStorage

## Como testar
1. Rodar o projeto com `npm start`
2. Acessar `/login`
3. Utilizar credenciais válidas para testar
```

---

## 6. Mantenha seu PR Atualizado

Caso a branch develop tenha sido atualizada enquanto você estava desenvolvendo, atualize sua branch com:

```bash
git checkout develop
git pull origin develop
git checkout feature/sua-branch
git rebase develop
```

---

**Obrigado por contribuir! 💙**
