#!/bin/bash
set -e

echo ">>> Rodando migrations..."
/home/dede/pessoal/melivra/_build/prod/rel/melivra/bin/melivra eval "Shlinkedin.Release.migrate"

echo ">>> Iniciando aplicação..."
exec _build/prod/rel/melivra/bin/melivra start
