#!/bin/sh

# This script is intended to be called from within the Docker container.

set -ex

bundle install
bundle exec jekyll serve --host 0.0.0.0 --port 4000
