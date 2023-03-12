#!/bin/sh

set -ex

MAPPED_PORT="$1"
: ${MAPPED_PORT:="4000"}

# Build the custom Docker image.
docker build -t ywen-ruby:latest .

# Start a container to serve the site locally.
docker run --rm \
  --volume "$PWD":/blog \
  --workdir /blog \
  --publish "$MAPPED_PORT:4000" \
  --name jekyll-server \
  ywen-ruby:latest \
  ./serve.sh
