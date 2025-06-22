#!/bin/bash
# list-models.sh - Pretty-print available model keys and metadata

echo "📚 Available Models:"
yq e '.models[] | "- " + .key + ": " + .name + " (" + .quant + ", " + .context + " context) — " + .use_case' models.yaml

