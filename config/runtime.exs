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

  config :shlinkedin, ShlinkedinWeb.Endpoint,
    http: [port: {:system, "PORT"}],
    url: [scheme: "https", host: "melivra.com", port: 443],
    force_ssl: [rewrite_on: [:x_forwarded_proto]],
    cache_static_manifest: "priv/static/cache_manifest.json",
    secret_key_base: secret_key_base

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :shlinkedin, Shlinkedin.Repo,
    username: System.get_env("DB_USER") || "",
    password: System.get_env("DB_PASS") || "",
    database: System.get_env("DB_NAME") || "",
    hostname: System.get_env("DB_HOST") || "",
    port: String.to_integer(System.get_env("DB_PORT") || "5432"),
    pool_size: 10
end
