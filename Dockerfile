FROM ghcr.io/ministryofjustice/analytical-platform-cloud-development-environment-base@sha256:23196c684e361181f1db5a82c2fefcdbc884f6bb4a6635b6bb425b2277c8c6cf

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="JupyterLab" \
      org.opencontainers.image.description="JupyterLab image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-jupyterlab"

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
