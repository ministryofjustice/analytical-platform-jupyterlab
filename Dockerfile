FROM public.ecr.aws/ubuntu/ubuntu@sha256:4f5ca1c8b7abe2bd1162e629cafbd824c303b98954b1a168526aca6021f8affe

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="JupyterLab" \
      org.opencontainers.image.description="JupyterLab image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-jupyterlab"

ENV CONDA_DIR="/opt/conda" \
    CONTAINER_USER="analyticalplatform" \
    CONTAINER_UID="1000" \
    CONTAINER_GROUP="analyticalplatform" \
    CONTAINER_GID="1000" \
    DEBIAN_FRONTEND="noninteractive" \
    MINICONDA_VERSION="24.5.0-0" \
    MINICONDA_SHA256="4b3b3b1b99215e85fd73fb2c2d7ebf318ac942a457072de62d885056556eb83e" \
    NODE_LTS_VERSION="20.15.1" \
    JUPYTERLAB_VERSION="4.2.4" \
    JUPYTERLAB_GIT_VERSION="0.50.1" \
    R_VERSION="4.4.1-1.2404.0" \
    PIP_BREAK_SYSTEM_PACKAGES="1"
ENV HOME="/home/${CONTAINER_USER}"
ENV PATH="${CONDA_DIR}/bin:${HOME}/.local/bin:${PATH}"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

# User Configuration
RUN <<EOF
# Ubuntu have added a user with UID 1000 already, but this is the UID we use in the tooling cluster
userdel --remove --force ubuntu

groupadd \
  --gid ${CONTAINER_GID} \
  ${CONTAINER_GROUP}

useradd \
  --uid ${CONTAINER_UID} \
  --gid ${CONTAINER_GROUP} \
  --create-home \
  --shell /bin/bash \
  ${CONTAINER_USER}
EOF

# Base
RUN apt-get update --yes \
  && apt-get install --yes --no-install-recommends \
    "apt-transport-https=2.7.14build2" \
    "ca-certificates=20240203" \
    "curl=8.5.0-2ubuntu10.1" \
    "fonts-liberation=1:2.1.5-3" \
    "git=1:2.43.0-1ubuntu7.1" \
    "gpg=2.4.4-2ubuntu17" \
    "jq=1.7.1-3build1" \
    "mandoc=1.14.6-1" \
    "pandoc=3.1.3+ds-2" \
    "python3-pip=24.0+dfsg-1ubuntu1" \
    "python3.12=3.12.3-1" \
    # MINIMAL NOTEBOOK
    "openssh-client=1:9.6p1-3ubuntu13" \
    "nano-tiny=7.2-2build1" \
    "less=590-2ubuntu2" \
    "texlive-fonts-recommended=2023.20240207-1" \
    "texlive-plain-generic=2023.20240207-1" \
    "texlive-xetex=2023.20240207-1" \
    "tzdata=2024a-3ubuntu1.1" \
    "unzip=6.0-28ubuntu4" \
    "vim-tiny=2:9.1.0016-1ubuntu7.1" \
    "xclip=0.13-3" \
  && apt-get clean --yes \
  && rm --force --recursive /var/lib/apt/lists/* \
  && install --directory --owner ${CONTAINER_USER} --group ${CONTAINER_GROUP} --mode 0755 /opt/jupyterlab

# Create alternative for nano -> nano-tiny
RUN update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10

# Backup Bash configuration
RUN <<EOF
cp "${HOME}/.bashrc" /opt/jupyterlab/.bashrc
cp "${HOME}/.bash_logout" /opt/jupyterlab/.bash_logout
cp "${HOME}/.profile" /opt/jupyterlab/.profile
EOF

# First run notice
COPY src/opt/jupyterlab/first-run-notice.txt /opt/jupyterlab/first-run-notice.txt
COPY src/etc/bash.bashrc.snippet /etc/bash.bashrc.snippet
RUN cat /etc/bash.bashrc.snippet >> /etc/bash.bashrc

# NodeJS
RUN <<EOF
curl --location --fail-with-body \
  "https://deb.nodesource.com/setup_lts.x" \
  --output "node.sh"

bash node.sh

apt-get install --yes \
    "nodejs=${NODE_LTS_VERSION}-1nodesource1" \
  && apt-get clean --yes \
  && rm --force --recursive /var/lib/apt/lists/* node.sh
EOF

# Miniconda
RUN <<EOF
curl --location --fail-with-body \
  "https://repo.anaconda.com/miniconda/Miniconda3-py312_${MINICONDA_VERSION}-Linux-x86_64.sh" \
  --output "miniconda.sh"

echo "${MINICONDA_SHA256} miniconda.sh" | sha256sum --check

bash miniconda.sh -b -p "${CONDA_DIR}"

chown --recursive "${CONTAINER_USER}":"${CONTAINER_GROUP}" "${CONDA_DIR}"
chown --recursive "${CONTAINER_USER}":"${CONTAINER_GROUP}" "${HOME}/.conda"

rm --force miniconda.sh
EOF

# R
RUN <<EOF
curl --location --fail-with-body \
  "https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc" \
  --output "marutter_pubkey.asc"

cat marutter_pubkey.asc | gpg --dearmor --output marutter_pubkey.gpg

install -D --owner root --group root --mode 644 marutter_pubkey.gpg /etc/apt/keyrings/marutter_pubkey.gpg

echo "deb [signed-by=/etc/apt/keyrings/marutter_pubkey.gpg] https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" > /etc/apt/sources.list.d/cran.list

apt-get update --yes

apt-get install --yes "r-base=${R_VERSION}"

apt-get clean --yes

rm --force --recursive marutter_pubkey.asc marutter_pubkey.gpg /var/lib/apt/lists/*
EOF

# Copy a script that we will use to correct permissions after running certain commands
COPY src/usr/local/bin/fix-permissions.sh /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

USER ${CONTAINER_UID}

# JupyterLab
WORKDIR /tmp
RUN conda config --add channels conda-forge \
  && conda install --yes \
    "conda-forge::jupyterlab==${JUPYTERLAB_VERSION}" \
    "conda-forge::jupyterlab-git==${JUPYTERLAB_GIT_VERSION}" \
    "conda-forge::nbclassic" \
    "conda-forge::notebook" \
  && jupyter server --generate-config \
  && conda clean --all -f -y \
  && npm cache clean --force \
  && jupyter lab clean \
  && rm -rf "${HOME}/.cache/yarn" \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "${HOME}"

# fix error when running conda:
RUN conda install --solver=classic --yes \
    "conda-forge::conda-libmamba-solver==24.7.0" \
    "conda-forge::libarchive==3.7.4" \
    "conda-forge::libmamba==1.5.8" \
    "conda-forge::libmambapy==1.5.8" \
  && conda clean --all -f -y \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "${HOME}"

ENV JUPYTER_PORT=8888
EXPOSE ${JUPYTER_PORT}

# Add an R mimetype option to specify how the plot returns from R to the browser
COPY --chown=${CONTAINER_UID}:${CONTAINER_GID} src/lib/R/etc/Rprofile.site "${CONDA_DIR}/lib/R/etc/"


# # BASE NOTEBOOK
# RUN <<EOF
# apt-get update --yes

# apt-get install --yes \
#   "fonts-liberation=1:2.1.5-3" \
#   "pandoc=3.1.3+ds-2"

# apt-get clean --yes

# rm --force --recursive /var/lib/apt/lists/*
# EOF

# # MINIMAL NOTEBOOK
# RUN <<EOF
# apt-get update --yes

# apt-get install --yes \
#   "less=590-2ubuntu2.1" \
#   "texlive-xetex=2023.20240207-1" \
#   "texlive-fonts-recommended=2023.20240207-1" \
#   "texlive-plain-generic=2023.20240207-1"

# apt-get clean --yes

# rm --force --recursive /var/lib/apt/lists/*
# EOF

USER ${CONTAINER_USER}
WORKDIR ${HOME}
EXPOSE 8080
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/healthcheck.sh /usr/local/bin/healthcheck.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]
