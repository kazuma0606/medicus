# Build stage
FROM haskell:9.4.8 as builder

WORKDIR /build

# Copy project configuration
COPY stack.yaml cabal.project /build/
COPY medicus-api/stack.yaml /build/medicus-api/
COPY medicus-api/medicus-api.cabal /build/medicus-api/
COPY medicus-engine.cabal /build/

# Pre-install dependencies (this layer is cached)
RUN stack build --only-dependencies medicus-api

# Copy source code
COPY src /build/src
COPY medicus-api/src /build/medicus-api/src
COPY medicus-api/app /build/medicus-api/app
COPY medicus-api/config /build/medicus-api/config

# Build the application
RUN stack build medicus-api --copy-bins --local-bin-path /build/bin

# Runtime stage
FROM ubuntu:22.04

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libgmp-dev \
    libnuma-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /build/bin/medicus-api /app/medicus-api

# Copy configuration files
COPY medicus-api/config /app/config

# Environment variables
ENV YESOD_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Start application
CMD ["/app/medicus-api"]
