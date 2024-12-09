#!/usr/bin/env bash

set -euo pipefail

find "${BARMAN_DATA_DIR}" \! -user barman -exec chown barman '{}' +
find "${BARMAN_DATA_DIR}" \! -group barman -exec chgrp barman '{}' +

echo "Generating barman.conf"
sed -i -E \
    -e "s,barman_home[[:space:]]*=.*$,barman_home = ${BARMAN_DATA_DIR}," \
    -e "s,configuration_files_directory[[:space:]]*=.*$,configuration_files_directory = ${BARMAN_CONF_DIR}," \
    /etc/barman.conf

echo "Generating cron schedules"
echo "${BARMAN_CRON_SCHEDULE} barman /usr/bin/barman cron" >> /etc/cron.d/barman-cron

echo "Running barman maintenance tasks immediately"
barman cron

echo "Starting cron"
exec "$@"