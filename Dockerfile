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
    # SCIPY NOTEBOOK
    "build-essential=12.10ubuntu1" \
    "cm-super=0.3.4-17" \
    "dvipng=1.15-1.1" \
    "ffmpeg=7:6.1.1-3ubuntu5" \
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

# scipy notebook packages
RUN conda install --yes \
    "bottleneck==1.3.7" \
    "conda-forge::blas=2.123=openblas" \
    "cython" \
    "matplotlib-base==3.8.4" \
    "sqlalchemy==2.0.30" \
    "altair==5.0.1" \
    "beautifulsoup4==4.12.3" \
    "bokeh==3.4.1" \
    "cloudpickle==3.0.0" \
    "dask-expr==1.1.0" \
    "dask==2024.5.0" \
    "dill==0.3.8" \
    "h5py==3.11.0" \
    "ipympl==0.9.4" \
    "ipywidgets==8.1.2" \
    "numba==0.60.0" \
    "numexpr==2.8.7" \
    "openpyxl==3.1.5" \
    "pandas==2.2.2" \
    "patsy==0.5.6" \
    "protobuf==4.25.3" \
    "scikit-image==0.23.2" \
    "scikit-learn==1.5.1" \
    "scipy==1.12.0" \
    "seaborn==0.13.2" \
    "statsmodels==0.14.2" \
    "sympy==1.12" \
    "widgetsnbextension==4.0.10" \
    "xlrd==2.0.1" \
  && conda clean --all -f -y \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "${HOME}"


WORKDIR /tmp
# note: facets GitHub repo archived as of 2024-07-24, still in jupyterlab image
# RUN git clone https://github.com/PAIR-code/facets --branch 1.0.0 && \
RUN git clone https://github.com/PAIR-code/facets \
  && jupyter nbclassic-extension install facets/facets-dist/ --sys-prefix \
  && rm -rf /tmp/facets \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "${HOME}"

# Import matplotlib the first time to build the font cache
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
  fix-permissions "${HOME}"

RUN conda config --set channel_priority flexible \
  && conda install --yes \
    "r-base==${R_VERSION%%-*}" \
    "r-caret" \
    "r-crayon" \
    # not installable because there are no viable options. r-devtools 2.4.5 would require r-base >=4.3,<4.4.0a0
    # "r-devtools" \
    "r-e1071" \
    "r-forecast" \
    "r-hexbin" \
    "r-htmltools" \
    "r-htmlwidgets" \
    "r-irkernel" \
    # not installable because there are no viable options. r-nycflights13 1.0.2 would require r-base >=4.3,<4.4.0a0
    # "r-nycflights13" \
    "r-randomforest" \
    # not installable because there are no viable options. r-rcurl [1.98_1.12-1.98_1.16] would require r-base >=4.3,<4.4.0a0
    # "r-rcurl" \
    "r-rmarkdown" \
    "r-rodbc" \
    "r-rsqlite" \
    "r-shiny" \
    # r-tidymodels [1.1.0-1.2.0] would require r-base >=4.3,<4.4.0a0
    # "r-tidymodels" \
    # r-tidyverse 2.0.0 would require r-base >=4.3,<4.4.0a0
    # "r-tidyverse" \
    # rpy2 3.5.11 would require r-base >=4.3,<4.4.0a0
    # "rpy2" \
    "unixodbc" \
  && conda clean --all -f -y \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "${HOME}"

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
