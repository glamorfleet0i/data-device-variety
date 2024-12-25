import os
import logging
import zlib
from typing import Final

from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

from encrypt import encrypt_and_compress_file
from sync_server import upload_to_filen

DELETE_ENCRYPTED_FILES_AFTER_UPLOAD: Final[bool] = os.environ.get("DELETE_ENCRYPTED_FILES_AFTER_UPLOAD", "true").lower() == "true"

logger = logging.getLogger("app.output_watcher")
observer = None

class OutputFileHandler(FileSystemEventHandler):
    def __init__(self):
        super().__init__()
        self.files_to_process = set()
    
    def on_created(self, event):
        try:
            if not event.is_directory:
                logger.info(f"New file created, waiting for file closure before uploading: \"{event.src_path}\"")
                self.files_to_process.add(event.src_path)
        except Exception as err:
            logger.error(f"Error in `on_created()` when processing file: \"{event.src_path}\"")
            logger.exception(err)

    def on_closed(self, event):
        try:
            if (event.src_path in self.files_to_process):
                self.files_to_process.remove(event.src_path)
                logger.info(f"File closed, preparing to compress, encrypt, and upload: \"{event.src_path}\"")
                file_size_mb = round(os.path.getsize(event.src_path) / 1024 / 1024, 2)
                file_crc32_hash = crc32(event.src_path)
                logger.info(f"The file \"{event.src_path}\" is {file_size_mb} MB with a CRC-32 hash of \"{file_crc32_hash}\" at the time of compression.")
                compress_and_upload_file(event.src_path, file_crc32_hash + "-")
        except Exception as err:
            logger.error(f"Error in `on_closed()` when processing file \"{event.src_path}\":")
            logger.exception(err)



def start_watching_directory(directory_path):
    global observer
    if observer:
        logger.info("A directory is already being watched, stopping...")
        stop_watching_current_directory()

    event_handler = OutputFileHandler()
    observer = Observer()
    observer.schedule(event_handler, directory_path, recursive=False)
    observer.start()
    logger.info(f"Started watching directory for new files: \"{directory_path}\"")


def stop_watching_current_directory():
    global observer
    if observer:
        observer.stop()
        observer.join()
        observer = None
        logger.info("Stopped watching current directory.")


def compress_and_upload_file(file_path: str, prepend_str = ""):
    """
    Compresses the created file with gzip, encrypts the compressed archive, and uploads the encrypted, compressed archive to the filen-sync-server.
    
    Args:
        file_path (str): Path to the created file.
        prepend_str (str): String to prepend to the filename.
    """    
    encrypted_file_path = encrypt_and_compress_file(file_path, prepend_str)
    if not encrypted_file_path:
        logger.error("Could not locate the encrypted file.")
        return
    
    upload_to_filen(encrypted_file_path)
    
    if DELETE_ENCRYPTED_FILES_AFTER_UPLOAD and os.path.exists(encrypted_file_path):
        os.remove(encrypted_file_path)
        logger.debug(f"Deleted encrypted file: \"{encrypted_file_path}\"")


def crc32(file_path: str, chunksize=65536):
    """
    Compute the CRC-32 hexadecimal checksum of the contents of the given file.
    """
    with open(file_path, "rb") as f:
        checksum = 0
        while (chunk := f.read(chunksize)) :
            checksum = zlib.crc32(chunk, checksum)
        return hex(checksum & 0xFFFFFFFF)[2:].zfill(8)