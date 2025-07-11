# Contribuindo para o Projeto

Obrigado por querer contribuir com este projeto! Para garantir um fluxo de trabalho organizado e limpo, siga as etapas abaixo cuidadosamente.

---
Recomendamos o uso do [asdf](https://asdf-vm.com/guide/getting-started.html) como gerenciador de versões para Elixir, Erlang e Node.js, a fim de facilitar a instalação e garantir compatibilidade entre ambientes.

## Material de Apoio

Como Elixir e programação funcional ainda não são temas muito explorados na faculdade como deveriam, reuni aqui alguns materiais que podem te ajudar na sua jornada de estudos com Elixir e Phoenix para desenvolvimento web — além da leitura das documentações oficiais, é claro.

### Recomendações:

- **Vídeo do Akita** – Uma ótima introdução ao Elixir, abordando fundamentos e a filosofia por trás da linguagem:  
  [https://www.youtube.com/watch?v=GeGXXfNvdSA&t=941s](https://www.youtube.com/watch?v=GeGXXfNvdSA&t=941s)

- **Playlist da Codemainer42** – Série de vídeos bem didática, cobrindo desde conceitos básicos até tópicos mais avançados:  
  [https://youtube.com/playlist?list=PLUMphNAA9pmrl_SpVZblu0YZ2HC9xNR2a](https://youtube.com/playlist?list=PLUMphNAA9pmrl_SpVZblu0YZ2HC9xNR2a) 

- **Blog do Akita** – No [akitaonrails.com](https://akitaonrails.com), pesquise por “Elixir” para encontrar mais de 15 posts com conteúdos aprofundados. Akita vai além da documentação básica e explora conceitos importantes do framework **Phoenix**, oferecendo insights valiosos para quem quer se aprofundar na stack.

  Um post recomendado é:  
  👉 [Phoenix: 15 Minute Blog - Comparison to Ruby on Rails](https://akitaonrails.com/2015/11/20/phoenix-15-minute-blog-comparison-to-ruby-on-rails)  
  Esse artigo é especialmente útil para quem já tem experiência com **Ruby on Rails**, pois compara passo a passo a construção de um blog nos dois frameworks.

  No início do post, Akita também indica um excelente tutorial em duas partes do Brandon Richey, ideal para quem quer ver um exemplo prático e completo da criação de um blog com Phoenix:

  - Parte 1: [Introduction](https://medium.com/hackernoon/introduction-fe138ac6079d#.ffl48saew)  
  - Parte 2: [Authorization](https://medium.com/hackernoon/writing-a-blog-engine-in-phoenix-part-2-authorization-814c06fa7c0)

- O **Phoenix LiveView** é amplamente utilizado neste projeto, especialmente nas áreas que exigem maior interatividade com o usuário. Ele permite construir interfaces ricas e dinâmicas com atualização em tempo real, sem a necessidade de escrever JavaScript explícito para cada interação.
    Para mais detalhes sobre sua utilização e API, consulte a documentação oficial:  
    [Phoenix.LiveView — v0.13.2](https://hexdocs.pm/phoenix_live_view/0.13.2/Phoenix.LiveView.html)




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
