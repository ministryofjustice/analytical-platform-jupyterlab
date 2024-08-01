#!/usr/bin/env bash

# Restore Bash configuration
if [[ ! -f "${HOME}/.bashrc" ]]; then
  cp /opt/jupyterlab/.bashrc ${HOME}/.bashrc
fi

if [[ ! -f "${HOME}/.bash_logout" ]]; then
  cp /opt/jupyterlab/.bash_logout ${HOME}/.bash_logout
fi

if [[ ! -f "${HOME}/.profile" ]]; then
  cp /opt/jupyterlab/.profile ${HOME}/.profile
fi

# Create workspace directory
if [[ ! -d "${HOME}/workspace" ]]; then
  mkdir --parent "${HOME}/workspace" \
    && fix-permissions "${HOME}"
fi

jupyter lab \
  --JupyterApp.answer_yes="True" \
  --ServerApp.open_browser="False" \
  --ServerApp.ip="0.0.0.0" \
  --ServerApp.port="8080" \
  --IdentityProvider.token="" \
  --LabApp.extension_manager="readonly" \
  --ServerApp.terminado_settings="shell_command=['/bin/bash']" \
  --notebook-dir="${HOME}/workspace"
