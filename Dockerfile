FROM debian:bookworm

# Install tools necessary to setup PDGD apt repo
RUN apt-get update && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
        && rm -rf /var/lib/apt/lists/*

# Setup PDGD apt repo
RUN curl -o /etc/apt/trusted.gpg.d/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        && bash -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'

# Create barman user
ENV BARMAN_UID=999
ENV BARMAN_GID=999

RUN groupadd --system -g ${BARMAN_GID} barman && \
    useradd --system \
        -u ${BARMAN_UID} -g ${BARMAN_GID} \
        --shell /bin/bash \
        barman

# Install barman
RUN apt-get update && apt-get install -y --no-install-recommends \
            barman \
            barman-cli \
            barman-cli-cloud \
            cron \
            postgresql-client-14 \
            tini \
        && rm -rf /var/lib/apt/lists/* \
        && rm -f /etc/crontab /etc/cron.*/* \
        && sed -i 's/\(.*pam_loginuid.so\)/#\1/' /etc/pam.d/cron

ENV BARMAN_CONF_DIR=/etc/barman.d/
ENV BARMAN_DATA_DIR=/var/lib/barman
ENV BARMAN_CRON_SCHEDULE="* * * * *"

VOLUME ${BARMAN_DATA_DIR}
VOLUME ${BARMAN_CONF_DIR}

COPY entrypoint.sh /
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["cron", "-L", "3", "-f"]
WORKDIR ${BARMAN_DATA_DIR}