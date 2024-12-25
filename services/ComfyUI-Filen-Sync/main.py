import logging
from logging.handlers import RotatingFileHandler
import os
import signal
import sys
import time

from output_watcher import start_watching_directory, stop_watching_current_directory

COMFY_UI_OUTPUT_DIR = os.environ.get("COMFY_UI_OUTPUT_DIR")
if not COMFY_UI_OUTPUT_DIR:
    raise ValueError(
        "The \"COMFY_UI_OUTPUT_DIR\" environment variable is not set. Please set it to the path of your ComfyUI output directory."
    )

def main():
    setup_logging()
    logger = logging.getLogger("app")
    
    logger.info("[Filen-Sync] Starting ComfyUI Filen Sync client...")
    start_watching_directory(COMFY_UI_OUTPUT_DIR)
    logger.info("[Filen-Sync] ComfyUI Filen Sync started. Press Ctrl+C or send SIGTERM to stop.")
    
    signal.signal(signal.SIGTERM, on_sigterm)
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("[Filen-Sync] Ctrl+C received. Stopping...")
        stop_watching_current_directory()
        logger.info("[Filen-Sync] ComfyUI Filen Sync stopped.")
    except Exception as e:
        logger.error(f"[Filen-Sync] An error occurred: {e}")
        stop_watching_current_directory()
        sys.exit(1)

def setup_logging():
    logger = logging.getLogger("app")
    logger.setLevel(logging.INFO)

    # [12/25/2024, 2:20:25 AM] [INFO] This is an example message.
    formatter = logging.Formatter(
        "[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%m/%d/%Y, %I:%M:%S %p",
    )

    os.makedirs('logs', exist_ok=True)
    file_handler = RotatingFileHandler('comfyui-filen-sync-logs/app.log', maxBytes=10*1024*1024, backupCount=10)  # 10MB limit * 10 logs = 100MB total log limit
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)

    stream_handler = logging.StreamHandler()
    stream_handler.setLevel(logging.INFO)
    stream_handler.setFormatter(formatter)

    logger.addHandler(file_handler)
    logger.addHandler(stream_handler)

def on_sigterm():
    logger = logging.getLogger("app")
    logger.info("[Filen-Sync] SIGTERM received, stopping....")
    stop_watching_current_directory()
    logger.info("[Filen-Sync] ComfyUI Filen Sync stopped.")

main()
