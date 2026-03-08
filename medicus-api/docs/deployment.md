# MEDICUS API Deployment Guide

This guide provides instructions for deploying the MEDICUS API in various environments.

## 1. Development Environment

### Prerequisites
- Haskell Stack
- MEDICUS Engine (local source)

### Running locally
```bash
cd medicus-api
stack build --fast
stack exec medicus-api
```

### Running with Docker Compose (Recommended)
```bash
cd medicus-api
docker compose up --build
```

---

## 2. Production Deployment

### Strategy: Docker Container
The recommended way to deploy MEDICUS API is using the provided `Dockerfile`.

#### 1. Build the production image
Run this from the project root:
```bash
docker build -t medicus-api:latest -f medicus-api/Dockerfile .
```

#### 2. Run the container
```bash
docker run -d \
  --name medicus-api \
  -p 3000:3000 \
  -e YESOD_ENV=production \
  -e PORT=3000 \
  -v $(pwd)/medicus-api/config:/app/config:ro \
  medicus-api:latest
```

---

## 3. Configuration Management

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `YESOD_ENV` | App environment (`development` or `production`) | `development` |
| `PORT` | Port to listen on | `3000` |
| `HOST` | Interface to bind to | `localhost` |
| `APPROOT` | Base URL for absolute links | (None) |

### Setting up `config/settings-prod.yml`
Ensure your production settings are properly configured:
- Set `development: false`
- Adjust `logging.level` to `INFO` or `WARN`
- Configure `cors.origins` to your frontend domain

---

## 4. Health Monitoring

### Health Endpoint
The API provides a health check endpoint at `/health`. Use this for load balancer health checks.

### Logging
In production, logs are output in **Structured JSON format** to `stdout`. 
Integrate these with log aggregators like ELK, CloudWatch, or Datadog.

---

## 5. Troubleshooting

### Connection Refused
- Check if the `PORT` is occupied.
- Ensure `HOST` is set to `0.0.0.0` inside Docker to accept external connections.

### 500 Internal Server Error
- Check JSON logs for `InternalError` or `MA.MEDICUSError`.
- Verify that `config/settings.yml` is readable by the application.

### Memory Issues
- The MEDICUS Engine can be memory-intensive for high-dimensional optimizations. 
- Ensure the runtime environment has at least 2GB of RAM.
