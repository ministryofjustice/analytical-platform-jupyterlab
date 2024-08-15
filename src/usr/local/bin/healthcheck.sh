#!/usr/bin/env bash

if [[ "$(curl --silent http://localhost:8080/api)" == *"version"* ]]; then
  exit 0
else
  exit 1
fi
