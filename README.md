# Como Rodar o melivra Localmente

Este guia é para quem deseja rodar o projeto localmente em ambiente de desenvolvimento.
Para fazer contribuições, siga as instruções em [CONTRIBUTING.md](CONTRIBUTING.md).
## Pré-requisitos

* [Elixir](https://elixir-lang.org/install.html) 1.16.2 (compiled with Erlang/OTP 26)
* [Erlang](https://www.erlang.org/downloads)
* [Node.js](https://nodejs.org/)
* [Docker + Docker Compose](https://docs.docker.com/compose/install/)

## 1. Suba o banco de dados PostgreSQL com Docker

de um up no banco de dados  `docker-compose.yml` com o seguinte comando:


```bash
docker-compose up --build -d
```

Esse comando irá subir o container do PostgreSQL e deixá-lo rodando em segundo plano.

## 2. Instale as dependências

```bash
mix deps.unlock --all; mix deps.update --all; mix deps.get
```

## 3. Configure o banco de dados

Com o banco já rodando via Docker, crie e migre o banco:

```bash
mix ecto.setup
```

## 4. Instale as dependências do frontend

```bash
cd assets
npm install
cd ..
```

## 5. Rode o servidor Phoenix

```bash
mix phx.server
```

Agora você pode acessar a aplicação em [`http://localhost:4000`](http://localhost:4000).

---

## Dicas adicionais

### Acesso ao painel de administração

1. Crie uma conta via interface da aplicação.
2. Torne o perfil admin diretamente via banco:

```sql
UPDATE profiles SET admin = true WHERE id = 1;
```

Acesse: [http://localhost:4000/admin](http://localhost:4000/admin)

### Integração com GIPHY

1. Solicite uma chave de API em: [https://support.giphy.com/hc/en-us/articles/360020283431-Request-A-GIPHY-API-Key](https://support.giphy.com/hc/en-us/articles/360020283431-Request-A-GIPHY-API-Key)
2. Exporte a variável de ambiente:

```bash
export GIPHY_API_KEY=sua_chave
```

3. Reinicie o servidor:

```bash
mix phx.server
```

---

## Aviso

Este projeto é um **fork** de [ShlinkedIn](https://github.com/cbh123/shlinked), um projeto open source criado por [cbh123](https://github.com/cbh123). Todos os créditos de concepção e estrutura inicial vão para o repositório original.

---

## Para quem quer aprender Elixir e Phoenix

* [Guia oficial do Elixir](https://elixir-lang.org/getting-started/introduction.html)
* [Documentação do Phoenix](https://hexdocs.pm/phoenix/overview.html)
* [Curso gratuito Phoenix LiveView (Pragmatic Studio)](https://pragmaticstudio.com/courses/phoenix-liveview)
* [Elixir School (Tutoriais)](https://elixirschool.com/pt/)
* [Vídeo: Clone do Twitter com Phoenix LiveView](https://www.phoenixframework.org/blog/build-a-real-time-twitter-clone-in-15-minutes-with-live-view-and-phoenix-1-5)

