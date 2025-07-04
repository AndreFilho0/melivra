import Config

if System.get_env("PHX_SERVER") do
  config :shlinkedin, ShlinkedinWeb.Endpoint, server: true
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "melivra.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :shlinkedin, ShlinkedinWeb.Endpoint,
    http: [port: port],
    url: [scheme: "https", host: host, port: 443],
    force_ssl: [rewrite_on: [:x_forwarded_proto]],
    cache_static_manifest: "priv/static/cache_manifest.json",
    secret_key_base: secret_key_base

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :ueberauth, Ueberauth.Strategy.Google.OAuth,
    client_id: System.get_env("GOOGLE_CLIENT_ID"),
    client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
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

  config :shlinkedin, Shlinkedin.Repo,
    username: System.get_env("DB_USER"),
    password: System.get_env("DB_PASS"),
    database: System.get_env("DB_NAME"),
    hostname: System.get_env("DB_HOST"),
    port: String.to_integer(System.get_env("DB_PORT") || "5432"),
    pool_size: 10

  config :shlinkedin, Shlinkedin.Mailer,
    adapter: Bamboo.MailgunAdapter,
    api_key: System.get_env("MAILGUN_API_KEY"),
    domain: "melivra.com"
end
