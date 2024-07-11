#!/usr/bin/env bash

jupyter lab \
  --JupyterApp.answer_yes="True" \
  --ServerApp.open_browser="False" \
  --ServerApp.ip="0.0.0.0" \
  --ServerApp.port="8080" \
  --IdentityProvider.token="" \
  --ServerApp.terminado_settings="shell_command=['/bin/bash']" \
  --notebook-dir="/home/analyticalplatform"
