#!/bin/bash

docker run -q --pull always -it --rm -v $(pwd):/app -w /app vluzrmos/domain-finder:latest $@