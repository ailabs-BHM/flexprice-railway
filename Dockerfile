FROM golang:1.25.12-alpine AS builder
WORKDIR /app

RUN apk add --no-cache git

RUN git clone --depth 1 https://github.com/flexprice/flexprice.git .

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux \
    go build -ldflags="-w -s" -trimpath \
      -o server cmd/server/main.go

RUN CGO_ENABLED=0 GOOS=linux \
    go build -ldflags="-w -s" -trimpath \
      -o migrate ./cmd/migrate

FROM ghcr.io/typst/typst:v0.13.1 AS typst

FROM alpine:3.20
WORKDIR /app

RUN apk add --no-cache ca-certificates postgresql-client

COPY --from=builder /app/server /app/server
COPY --from=builder /app/migrate /app/migrate
COPY --from=typst /bin/typst /usr/local/bin/
COPY --from=builder /app/internal ./internal
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/migrations ./migrations

RUN chmod +x /app/server /app/migrate

COPY <<'ENTRYPOINT' /app/entrypoint.sh
#!/bin/sh
set -e

# Apply the database schema before accepting traffic.
echo "Running Ent migrations..."
/app/migrate postgres --timeout 300

echo "Starting server..."
exec /app/server
ENTRYPOINT

RUN chmod +x /app/entrypoint.sh

EXPOSE 8080
CMD ["/app/entrypoint.sh"]
