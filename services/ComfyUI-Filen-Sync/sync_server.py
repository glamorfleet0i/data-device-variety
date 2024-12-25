import os
import logging
from typing import Final

import requests

FILEN_SYNC_URL = os.environ.get("FILEN_SYNC_URL")
if not FILEN_SYNC_URL:
    raise ValueError("A \"FILEN_SYNC_URL\" for the filen-sync-server is required, but was not found in the system environment variables.")

FILEN_SYNC_API_KEY = os.environ.get("FILEN_SYNC_API_KEY")
if not FILEN_SYNC_API_KEY:
    raise ValueError("A \"FILEN_SYNC_API_KEY\" for authenticating with the filen-sync-server is required, but was not found in the system environment variables.")

FILEN_SYNC_FILE_FIELD_NAME = os.environ.get("FILEN_SYNC_FILE_FIELD_NAME")
if not FILEN_SYNC_FILE_FIELD_NAME:
    raise ValueError("The \"FILEN_SYNC_FILE_FIELD_NAME\" for the filen-sync-server upload endpoint is required, but was not found in the system environment variables.")

FILEN_SYNC_UPLOAD_TIMEOUT: Final[int] = int(os.environ.get("FILEN_SYNC_UPLOAD_TIMEOUT", 900))
FILEN_SYNC_UPLOAD_ENDPOINT: Final[str] = f"{FILEN_SYNC_URL}/upload"

logger = logging.getLogger("app.encrypt")

def upload_to_filen(file_path):
    logger.info(f"Uploading file \"{file_path}\" to Filen...")
    
    headers = { 'authorization': f'Bearer {FILEN_SYNC_API_KEY}' }
    files = { FILEN_SYNC_FILE_FIELD_NAME: open(file_path, 'rb') }
    response = requests.post(FILEN_SYNC_UPLOAD_ENDPOINT, headers=headers, files=files, timeout=FILEN_SYNC_UPLOAD_TIMEOUT)

    if response.status_code == 201:
        uploaded_file_path = response.json().get('filenPath')
        logger.info(f"Successfully uploaded file to Filen at \"{uploaded_file_path}\".")
        return uploaded_file_path
    else:
        logger.error(f"Failed to upload file.")
        logger.error(response.text)
        return None
