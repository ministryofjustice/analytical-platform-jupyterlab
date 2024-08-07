#!/usr/bin/env bash

# Restore Bash configuration
if [[ ! -f "/home/analyticalplatform/.bashrc" ]]; then
  cp /opt/jupyterlab/.bashrc /home/analyticalplatform/.bashrc
fi

if [[ ! -f "/home/analyticalplatform/.bash_logout" ]]; then
  cp /opt/jupyterlab/.bash_logout /home/analyticalplatform/.bash_logout
fi

if [[ ! -f "/home/analyticalplatform/.profile" ]]; then
  cp /opt/jupyterlab/.profile /home/analyticalplatform/.profile
fi

# Create workspace directory
if [[ ! -d "/home/analyticalplatform/workspace" ]]; then
  mkdir --parent /home/analyticalplatform/workspace
fi

jupyter lab \
  --JupyterApp.answer_yes="True" \
  --ServerApp.open_browser="False" \
  --ServerApp.ip="0.0.0.0" \
  --ServerApp.port="8080" \
  --IdentityProvider.token="" \
  --LabApp.extension_manager="readonly" \
  --ServerApp.terminado_settings="shell_command=['/bin/bash']" \
  --notebook-dir="/home/analyticalplatform/workspace"
