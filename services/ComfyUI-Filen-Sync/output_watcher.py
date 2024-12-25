import os
import logging
from typing import Final

from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

from encrypt import encrypt_and_compress_file
from sync_server import upload_to_filen

DELETE_ENCRYPTED_FILES_AFTER_UPLOAD: Final[bool] = os.environ.get("DELETE_ENCRYPTED_FILES_AFTER_UPLOAD", "true").lower() == "true"

logger = logging.getLogger("app.output_watcher")
observer = None

class OutputFileCreationHandler(FileSystemEventHandler):
    def on_created(self, event):
        if not event.is_directory:
            file_path = event.src_path
            try:
                on_file_created(file_path)
            except Exception as err:
                logger.error(f"Error processing file \"{file_path}\":")
                logger.exception(err)



def start_watching_directory(directory_path):
    global observer
    if observer:
        logger.info("A directory is already being watched, stopping...")
        stop_watching_current_directory()

    event_handler = OutputFileCreationHandler()
    observer = Observer()
    observer.schedule(event_handler, directory_path, recursive=False)
    observer.start()
    logger.info(f"Started watching directory: {directory_path}")

def stop_watching_current_directory():
    global observer
    if observer:
        observer.stop()
        observer.join()
        observer = None
        logger.info("Stopped watching current directory.")

def on_file_created(file_path: str):
    """
    Compresses the created file with gzip, encrypts the compressed archive, and uploads the encrypted, compressed archive to the filen-sync-server.
    
    Args:
        file_path (str): Path to the created file.
    """
    logger.info(f"New file found: {file_path}")
    
    encrypted_file_path = encrypt_and_compress_file(file_path)
    if not encrypted_file_path:
        logger.error("Could not locate the encrypted file.")
        return
    
    upload_to_filen(encrypted_file_path)
    
    if DELETE_ENCRYPTED_FILES_AFTER_UPLOAD and os.path.exists(encrypted_file_path):
        os.remove(encrypted_file_path)
    
