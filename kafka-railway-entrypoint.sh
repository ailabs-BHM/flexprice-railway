#!/usr/bin/env bash
set -euo pipefail

IFS=',' read -ra kafka_log_dirs <<< "${KAFKA_LOG_DIRS:-/var/lib/kafka/data}"
for kafka_log_dir in "${kafka_log_dirs[@]}"; do
  mkdir -p "$kafka_log_dir"
  chown -R appuser:appuser "$kafka_log_dir"
done

exec su -s /bin/bash appuser -c 'exec "$@"' kafka-railway \
  /etc/kafka/docker/run "$@"
