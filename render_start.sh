#!/bin/bash
echo "[OpenAlgo-Lite] Starting optimized version for Render FREE tier..."

# Memory optimization - disable heavy features
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
export DISABLE_JUPYTER=1
export DISABLE_PLOTTING=1
export LOG_LEVEL=ERROR
export FORCE_COLOR=0

# Generate minimal .env
echo "[OpenAlgo-Lite] Generating optimized .env..."

cat > .env << EOF
# OpenAlgo Lite - Memory Optimized
ENV_CONFIG_VERSION = '1.0.6'

# Broker
BROKER_API_KEY = '${BROKER_API_KEY}'
BROKER_API_SECRET = '${BROKER_API_SECRET}'
BROKER_API_KEY_MARKET = ''
BROKER_API_SECRET_MARKET = ''

# URLs
REDIRECT_URL = '${REDIRECT_URL}'
HOST_SERVER = '${HOST_SERVER}'

# Valid Brokers
VALID_BROKERS = 'fyers'

# Security
APP_KEY = '${APP_KEY}'
API_KEY_PEPPER = '${API_KEY_PEPPER}'

# Database - Use SQLite (lightest)
DATABASE_URL = 'sqlite:///db/openalgo.db'
LATENCY_DATABASE_URL = 'sqlite:///db/latency.db'
LOGS_DATABASE_URL = 'sqlite:///db/logs.db'
SANDBOX_DATABASE_URL = 'sqlite:///db/sandbox.db'

# Ngrok
NGROK_ALLOW = 'FALSE'

# Flask - Minimal settings
FLASK_HOST_IP = '0.0.0.0'
FLASK_PORT = '${PORT}'
FLASK_DEBUG = 'False'
FLASK_ENV = 'production'

# WebSocket - DISABLED for memory
WEBSOCKET_HOST = '0.0.0.0'
WEBSOCKET_PORT = '8765'
WEBSOCKET_URL = ''

# ZeroMQ - DISABLED
ZMQ_HOST = '0.0.0.0'
ZMQ_PORT = '5555'

# Logging - Minimal
LOG_TO_FILE = 'False'
LOG_LEVEL = 'ERROR'
LOG_DIR = 'log'
LOG_FORMAT = '%(levelname)s: %(message)s'
LOG_RETENTION = '1'
LOG_COLORS = 'False'
FORCE_COLOR = '0'

# Rate Limits - Reduced
LOGIN_RATE_LIMIT_MIN = '3 per minute'
LOGIN_RATE_LIMIT_HOUR = '15 per hour'
RESET_RATE_LIMIT = '10 per hour'
API_RATE_LIMIT = '30 per second'
ORDER_RATE_LIMIT = '5 per second'
SMART_ORDER_RATE_LIMIT = '1 per second'
WEBHOOK_RATE_LIMIT = '50 per minute'
STRATEGY_RATE_LIMIT = '100 per minute'

# API
SMART_ORDER_DELAY = '0.5'
SESSION_EXPIRY_TIME = '03:00'

# CORS - Minimal
CORS_ENABLED = 'TRUE'
CORS_ALLOWED_ORIGINS = '${HOST_SERVER}'
CORS_ALLOWED_METHODS = 'GET,POST,DELETE,PUT'
CORS_ALLOWED_HEADERS = 'Content-Type,Authorization'
CORS_EXPOSED_HEADERS = ''
CORS_ALLOW_CREDENTIALS = 'FALSE'
CORS_MAX_AGE = '3600'

# CSP - Disabled for memory
CSP_ENABLED = 'FALSE'

# CSRF
CSRF_ENABLED = 'TRUE'
CSRF_TIME_LIMIT = ''

# Cookies
SESSION_COOKIE_NAME = 'session'
CSRF_COOKIE_NAME = 'csrf_token'
EOF

echo "[OpenAlgo-Lite] Config created - memory optimized"

# Create minimal directories
mkdir -p db log 2>/dev/null || true

# DO NOT start WebSocket server (saves ~100 MB RAM)
echo "[OpenAlgo-Lite] Skipping WebSocket proxy to save memory"

# Start app with minimal workers and memory optimizations
echo "[OpenAlgo-Lite] Starting lightweight app on port ${PORT}..."

# Use gunicorn with minimal memory footprint
exec gunicorn \
    --worker-class sync \
    --workers 1 \
    --threads 2 \
    --worker-tmp-dir /dev/shm \
    --max-requests 50 \
    --max-requests-jitter 10 \
    --timeout 120 \
    --graceful-timeout 30 \
    --keep-alive 5 \
    --log-level error \
    --access-logfile - \
    --error-logfile - \
    --bind 0.0.0.0:${PORT} \
    --preload \
    app:app
