# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install security and build dependencies
RUN apk add --no-cache ca-certificates git && \
    adduser -D -g '' appuser

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build with security flags
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags=-static' \
    -o /go/bin/api-service

# Final stage
FROM scratch

# Copy certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the binary
COPY --from=builder /go/bin/api-service /api-service

# Copy the user
COPY --from=builder /etc/passwd /etc/passwd

# Use non-root user
USER appuser

# Expose metrics port
EXPOSE 8080

ENTRYPOINT ["/api-service"] 