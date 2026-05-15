#!/bin/bash

set -e

sleep 1
git fetch
git reset --hard origin/master
poetry install
poetry run mkdocs build
mkdir -p /srv/deploy/router-lab-docs
cp -r site/* /srv/deploy/router-lab-docs/
