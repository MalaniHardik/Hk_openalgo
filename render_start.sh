#!/bin/bash
echo "[OpenAlgo-Render] Starting up..."

# ============================================
# RENDER ENVIRONMENT - SIMPLIFIED START
# ============================================

# Generate .env from Render environment variables
echo "[OpenAlgo-Render] Generating .env file..."

cat > .env << EOF
# OpenAlgo Environment Configuration
ENV_CONFIG_VERSION = '1.0.4'

# Broker Configuration
BROKER_API_KEY = '${BROKER_API_KEY}'
BROKER_API_SECRET = '${BROKER_API_SECRET}'

# Redirect URL
REDIRECT_URL = '${REDIRECT_URL}'

# Valid Brokers
VALID_BROKERS = 'fyers'

# Security
APP_KEY = '${APP_KEY}'
API_KEY_PEPPER = '${API_KEY_PEPPER}'

# Database
DATABASE_URL = '${DATABASE_URL:-sqlite:///db/openalgo.db}'
LATENCY_DATABASE_URL = '${LATENCY_DATABASE_URL:-sqlite:///db/latency.db}'
LOGS_DATABASE_URL = '${LOGS_DATABASE_URL:-sqlite:///db/logs.db}'
SANDBOX_DATABASE_URL = '${SANDBOX_DATABASE_URL:-sqlite:///db/sandbox.db}'

# Ngrok - Disabled
NGROK_ALLOW = 'FALSE'

# Host Server
HOST_SERVER = '${HOST_SERVER}'

# Flask Configuration
FLASK_HOST_IP = '0.0.0.0'
FLASK_PORT = '${PORT}'
FLASK_DEBUG = 'False'
FLASK_ENV = 'production'

# WebSocket Configuration
WEBSOCKET_HOST = '0.0.0.0'
WEBSOCKET_PORT = '8765'
WEBSOCKET_URL = 'wss://hk-openalgo.onrender.com/ws'

# ZeroMQ Configuration
ZMQ_HOST = '0.0.0.0'
ZMQ_PORT = '5555'

# Logging
LOG_TO_FILE = 'True'
LOG_LEVEL = 'INFO'
LOG_DIR = 'log'
LOG_FORMAT = '[%(asctime)s] %(levelname)s in %(module)s: %(message)s'
LOG_RETENTION = '14'
LOG_COLORS = 'True'
FORCE_COLOR = '1'

# Rate Limits
LOGIN_RATE_LIMIT_MIN = '5 per minute'
LOGIN_RATE_LIMIT_HOUR = '25 per hour'
RESET_RATE_LIMIT = '15 per hour'
API_RATE_LIMIT = '50 per second'
ORDER_RATE_LIMIT = '10 per second'
SMART_ORDER_RATE_LIMIT = '2 per second'
WEBHOOK_RATE_LIMIT = '100 per minute'
STRATEGY_RATE_LIMIT = '200 per minute'

# API
SMART_ORDER_DELAY = '0.5'
SESSION_EXPIRY_TIME = '03:00'

# CORS
CORS_ENABLED = 'TRUE'
CORS_ALLOWED_ORIGINS = '${HOST_SERVER}'
CORS_ALLOWED_METHODS = 'GET,POST,DELETE,PUT,PATCH'
CORS_ALLOWED_HEADERS = 'Content-Type,Authorization,X-Requested-With'
CORS_EXPOSED_HEADERS = ''
CORS_ALLOW_CREDENTIALS = 'FALSE'
CORS_MAX_AGE = '86400'

# CSP
CSP_ENABLED = 'TRUE'
CSP_REPORT_ONLY = 'FALSE'
CSP_DEFAULT_SRC = "'self'"
CSP_SCRIPT_SRC = "'self' 'unsafe-inline' https://cdn.socket.io"
CSP_STYLE_SRC = "'self' 'unsafe-inline'"
CSP_IMG_SRC = "'self' data:"
CSP_CONNECT_SRC = "'self' wss://hk-openalgo.onrender.com wss: ws:"
CSP_FONT_SRC = "'self'"
CSP_OBJECT_SRC = "'none'"
CSP_MEDIA_SRC = "'self' data:"
CSP_FRAME_SRC = "'self'"
CSP_FORM_ACTION = "'self'"
CSP_FRAME_ANCESTORS = "'self'"
CSP_BASE_URI = "'self'"
CSP_UPGRADE_INSECURE_REQUESTS = 'TRUE'
CSP_REPORT_URI = ''

# CSRF
CSRF_ENABLED = 'TRUE'
CSRF_TIME_LIMIT = ''

# Cookies
SESSION_COOKIE_NAME = 'session'
CSRF_COOKIE_NAME = 'csrf_token'
EOF

echo "[OpenAlgo-Render] .env file created"

# Create necessary directories
mkdir -p db log log/strategies strategies strategies/scripts keys 2>/dev/null || true
chmod -R 755 db log strategies 2>/dev/null || true
chmod 700 keys 2>/dev/null || true

# Start WebSocket proxy in background
echo "[OpenAlgo-Render] Starting WebSocket proxy..."
python -m websocket_proxy.server &
WEBSOCKET_PID=$!

# Cleanup on exit
cleanup() {
    echo "[OpenAlgo-Render] Shutting down..."
    kill $WEBSOCKET_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# Start main application with gunicorn
echo "[OpenAlgo-Render] Starting application on port ${PORT}..."
exec gunicorn \
    --worker-class eventlet \
    --workers 1 \
    --bind 0.0.0.0:${PORT} \
    --timeout 300 \
    --graceful-timeout 30 \
    --log-level info \
    app:app
