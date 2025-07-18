# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :shlinkedin,
  ecto_repos: [Shlinkedin.Repo]

# config/config.exs
config :shlinkedin, Shlinkedin.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: "",
  domain: "melivra.com"

# Configures the endpoint
config :shlinkedin, ShlinkedinWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "fNbu+cPivBuXaOxrZhaGCheLwkzl4oiVgpxCFE65onLpGeHDg2qUY/MfL0t+TJLG",
  render_errors: [view: ShlinkedinWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Shlinkedin.PubSub,
  live_view: [signing_salt: "aeT/X9uj"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2018 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :money,
  default_currency: :SHLINK,
  custom_currencies: [
    SHLINK: %{name: "MeLI Coin", symbol: "ML", exponent: 2}
  ]

config :ex_aws,
  access_key_id: "",
  secret_access_key: "",
  # O MinIO usa "us-east-1" por padrão, mas pode ser qualquer valor
  region: "us-east-1",
  s3: [
    # Use "http://" se o MinIO não estiver com SSL
    scheme: "https://",
    # Endpoint do MinIO
    host: "bucket.melivra.com",
    # Porta do MinIO (443 para HTTPS, 80 para HTTP)
    port: 443
  ]

config :shlinkedin, [
  {Oban,
   [
     engine: Oban.Engines.Basic,
     notifier: Oban.Notifiers.Postgres,
     queues: [provas: 2],
     repo: Shlinkedin.Repo
   ]}
]

config :tailwind,
  version: "3.0.22",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

use Mix.Config

config :openai,
  # find it at https://beta.openai.com/account/api-keys
  api_key: System.get_env("OPENAI_KEY"),
  # find it at https://beta.openai.com/account/api-keys
  organization_key: System.get_env("OPENAI_ORG")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
