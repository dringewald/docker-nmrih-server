#!/bin/sh
docker images -q "holt31/nmrih-server" | uniq | xargs docker rmi --force
docker system prune
