[
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs,heex,eex,leex}"],
  subdirectories: ["priv/*/migrations"]
]
