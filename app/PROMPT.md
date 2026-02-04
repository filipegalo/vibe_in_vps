# AI Coding Assistant Prompt

This prompt helps you build an app compatible with the vibe_in_vps deployment system. Copy and customize this prompt when using AI coding assistants like Claude, Cursor, GitHub Copilot, or ChatGPT.

---

## Template Prompt

```
I need to build a [describe your app type] application that will be deployed using Docker.

CRITICAL REQUIREMENTS:
1. The app MUST expose port 3000
2. The app MUST include a /health endpoint that returns 200 OK
3. The Dockerfile should include a HEALTHCHECK command
4. Use environment variables for all configuration (no hardcoded values)

TECHNICAL STACK:
- [Your framework: e.g., Node.js + Express, Python + Flask, Go + Gin]
- [Database if needed: PostgreSQL, MySQL, Redis]
- [Other dependencies]

FEATURES NEEDED:
- [List your features here]
- [Feature 2]
- [Feature 3]

ENVIRONMENT VARIABLES:
The app should read these from environment variables:
- PORT (default: 3000)
- NODE_ENV (production, development)
- DATABASE_URL (if using a database)
- [Your custom env vars]

DOCKERFILE REQUIREMENTS:
- Multi-stage build (for smaller images)
- Run as non-root user
- Include HEALTHCHECK command: HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
- Expose port 3000: EXPOSE 3000
- Use alpine or slim base images when possible

HEALTH ENDPOINT REQUIREMENTS:
The /health endpoint should:
- Return HTTP 200 status
- Return JSON: {"status": "ok", "timestamp": "..."}
- Check critical dependencies (database connection, etc.)
- Respond within 5 seconds

Please generate:
1. Complete application code
2. Dockerfile
3. package.json / requirements.txt / go.mod (as appropriate)
4. .dockerignore file
5. README with local development instructions
```

---

## Example Prompts by Framework

### Node.js + Express

```
Build a REST API using Node.js and Express that will be deployed with Docker.

REQUIREMENTS:
- Expose port 3000
- Include /health endpoint returning {"status": "ok", "timestamp": "2024-01-01T00:00:00Z"}
- Use environment variables: PORT, NODE_ENV, DATABASE_URL
- Connect to PostgreSQL database
- Include CRUD endpoints for [your resource]

Dockerfile must:
- Use node:20-alpine as base
- Multi-stage build
- Run as non-root user
- Include HEALTHCHECK: HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
- EXPOSE 3000
```

### Python + Flask

```
Build a REST API using Python and Flask that will be deployed with Docker.

REQUIREMENTS:
- Expose port 3000 (not the default Flask 5000)
- Include /health endpoint returning {"status": "ok", "timestamp": "..."}
- Use environment variables: PORT, FLASK_ENV, DATABASE_URL
- Connect to PostgreSQL database
- Include endpoints for [your features]

Dockerfile must:
- Use python:3.11-slim as base
- Multi-stage build with pip dependencies
- Run as non-root user
- Include HEALTHCHECK: HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
- EXPOSE 3000
- Use gunicorn for production
```

### Go + Gin

```
Build a REST API using Go and Gin framework that will be deployed with Docker.

REQUIREMENTS:
- Expose port 3000
- Include /health endpoint returning {"status": "ok", "timestamp": "..."}
- Use environment variables: PORT, ENV, DATABASE_URL
- Connect to PostgreSQL using pgx
- Include endpoints for [your features]

Dockerfile must:
- Multi-stage build (golang:1.21 for build, alpine for runtime)
- Run as non-root user
- Include HEALTHCHECK: HEALTHCHECK CMD wget --spider --quiet http://localhost:3000/health || exit 1
- EXPOSE 3000
- Static binary compilation
```

### Next.js + React

```
Build a Next.js application that will be deployed with Docker.

REQUIREMENTS:
- Expose port 3000
- Include /api/health endpoint returning {"status": "ok", "timestamp": "..."}
- Use environment variables via next.config.js
- Server-side rendering enabled
- Include pages for [your features]

Dockerfile must:
- Use node:20-alpine as base
- Multi-stage build (dependencies → build → runtime)
- Run as non-root user
- Include HEALTHCHECK: HEALTHCHECK CMD curl -f http://localhost:3000/api/health || exit 1
- EXPOSE 3000
- Production build with output: 'standalone'
```

---

## Health Endpoint Examples

### Minimal Health Check (Always Use This Minimum)

```javascript
// Node.js/Express
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});
```

### Health Check with Database Verification

```javascript
// Node.js/Express with PostgreSQL
app.get('/health', async (req, res) => {
  try {
    // Test database connection
    await pool.query('SELECT 1');

    res.status(200).json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error.message
    });
  }
});
```

```python
# Python/Flask with PostgreSQL
@app.route('/health')
def health():
    try:
        # Test database connection
        db.session.execute('SELECT 1')

        return jsonify({
            'status': 'ok',
            'timestamp': datetime.now().isoformat(),
            'database': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'error',
            'timestamp': datetime.now().isoformat(),
            'database': 'disconnected',
            'error': str(e)
        }), 503
```

```go
// Go/Gin with PostgreSQL
func healthHandler(c *gin.Context) {
    // Test database connection
    err := db.Ping()

    if err != nil {
        c.JSON(503, gin.H{
            "status": "error",
            "timestamp": time.Now().Format(time.RFC3339),
            "database": "disconnected",
            "error": err.Error(),
        })
        return
    }

    c.JSON(200, gin.H{
        "status": "ok",
        "timestamp": time.Now().Format(time.RFC3339),
        "database": "connected",
    })
}
```

---

## Dockerfile Template

```dockerfile
# Multi-stage build example (Node.js)
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Build if needed (for TypeScript, etc.)
# RUN npm run build

# Runtime stage
FROM node:20-alpine

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start application
CMD ["node", "server.js"]
```

---

## Testing Your App Locally

Before deploying, test your app locally:

```bash
# Build the Docker image
docker build -t my-app .

# Run the container
docker run -p 3000:3000 \
  -e NODE_ENV=production \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  my-app

# Test the health endpoint
curl http://localhost:3000/health

# Expected response:
# {"status":"ok","timestamp":"2024-01-01T00:00:00.000Z"}
```

---

## Common Pitfalls to Avoid

❌ **Don't hardcode port 5000, 8080, etc.** - Always use port 3000 or read from PORT env var
❌ **Don't forget the health endpoint** - Deployment will fail without it
❌ **Don't skip HEALTHCHECK in Dockerfile** - Required for monitoring
❌ **Don't hardcode configuration** - Use environment variables
❌ **Don't run as root** - Create and use a non-root user
❌ **Don't skip .dockerignore** - Reduces image size and build time
❌ **Don't use large base images** - Prefer alpine or slim variants

✅ **Do expose port 3000**
✅ **Do include /health endpoint**
✅ **Do use environment variables**
✅ **Do test locally before deploying**
✅ **Do follow 12-factor app principles**

---

## Need Help?

- Check `docs/SETUP.md` for deployment instructions
- Check `docs/RUNBOOK.md` for operations guide
- Review the example app in `/app` directory
- See `deploy/docker-compose.yml` for environment variable setup

---

## Quick Checklist

Before deploying your app, verify:

- [ ] Port 3000 is exposed in Dockerfile
- [ ] EXPOSE 3000 is in Dockerfile
- [ ] /health endpoint returns 200 OK with JSON
- [ ] HEALTHCHECK command is in Dockerfile
- [ ] All configuration uses environment variables
- [ ] Dockerfile uses multi-stage build
- [ ] App runs as non-root user
- [ ] .dockerignore file exists
- [ ] Tested locally with Docker
- [ ] Health endpoint responds within 5 seconds
