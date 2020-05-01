#!/bin/sh
git pull
~/.local/bin/mkdocs build
sudo cp -r site/* /srv/router-lab-docs/
