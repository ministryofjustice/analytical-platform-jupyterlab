FROM ghcr.io/ministryofjustice/analytical-platform-cloud-development-environment-base@sha256:c5b1ca761b4a9db72506ed23831c525df52e5398177c041638d8f0b80c47356e

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="JupyterLab" \
      org.opencontainers.image.description="JupyterLab image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-jupyterlab"

ENV JUPYTERLAB_VERSION="4.2.4" \
    JUPYTERLAB_GIT_VERSION="0.50.1"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

# First Run Notice
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt

# JupyterLab
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/requirements.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/requirements.txt
RUN <<EOF
pip install --no-cache-dir --requirement ${ANALYTICAL_PLATFORM_DIRECTORY}/requirements.txt
EOF

USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}
EXPOSE 8080
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/healthcheck.sh /usr/local/bin/healthcheck.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]
