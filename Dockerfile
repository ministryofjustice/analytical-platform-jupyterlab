FROM ghcr.io/ministryofjustice/analytical-platform-cloud-development-environment-base@sha256:642f27835387423029b56cf298d671259d56f505157bcfae2d2a193993f4ca35

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="JupyterLab" \
      org.opencontainers.image.description="JupyterLab image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-jupyterlab"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

# First Run Notice
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt

# JupyterLab
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/requirements-jupyterlab.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/requirements-jupyterlab.txt
RUN <<EOF
pip install --no-cache-dir --requirement ${ANALYTICAL_PLATFORM_DIRECTORY}/requirements-jupyterlab.txt
EOF

# Base + SciPy
# Base is used by users when installing with different versions of Python
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/requirements-base.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/requirements-base.txt
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/requirements-scipy.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/requirements-scipy.txt

USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}
EXPOSE 8080
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/healthcheck.sh /usr/local/bin/healthcheck.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]
