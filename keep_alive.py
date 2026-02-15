"""
Keep Alive Script - Prevents Render Free Tier from Sleeping
Pings itself every 10 minutes to stay awake 24/7
Optimized for low resource usage
"""

import os
import time
import requests
import logging
from datetime import datetime
from threading import Thread

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

class KeepAlive:
    def __init__(self):
        # Get service URL from environment
        self.url = os.environ.get('RENDER_EXTERNAL_URL', 'http://localhost:5000')
        
        # Ping interval (default 10 minutes = 600 seconds)
        self.interval = int(os.environ.get('SELF_PING_INTERVAL', 600))
        
        # Health check endpoint
        self.health_endpoint = f"{self.url}/health"
        
        logger.info(f"Keep Alive initialized")
        logger.info(f"URL: {self.url}")
        logger.info(f"Interval: {self.interval} seconds ({self.interval/60} minutes)")
    
    def ping(self):
        """Send ping to keep service awake"""
        try:
            response = requests.get(self.health_endpoint, timeout=10)
            
            if response.status_code == 200:
                logger.info(f"✅ Ping successful - Service alive at {datetime.now().strftime('%H:%M:%S')}")
            else:
                logger.warning(f"⚠️ Ping returned status {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Ping failed: {e}")
        except Exception as e:
            logger.error(f"❌ Unexpected error: {e}")
    
    def start(self):
        """Start the keep-alive loop"""
        logger.info("🚀 Starting Keep Alive service...")
        
        # Wait 30 seconds for app to start
        time.sleep(30)
        
        while True:
            try:
                self.ping()
                
                # Wait for next ping
                time.sleep(self.interval)
                
            except KeyboardInterrupt:
                logger.info("⛔ Keep Alive stopped by user")
                break
            except Exception as e:
                logger.error(f"❌ Loop error: {e}")
                time.sleep(60)  # Wait 1 minute on error

def run_keep_alive():
    """Run keep alive in background thread"""
    keeper = KeepAlive()
    keeper.start()

if __name__ == "__main__":
    # Run directly
    run_keep_alive()
else:
    # Run in background thread when imported
    thread = Thread(target=run_keep_alive, daemon=True)
    thread.start()
    logger.info("Keep Alive thread started in background")
