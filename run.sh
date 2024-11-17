#!/bin/bash

docker run -q -it --rm -v $(pwd):/app -w /app vluzrmos/domain-finder:latest $@