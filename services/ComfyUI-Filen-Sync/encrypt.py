import os
import gzip
import logging
import tempfile
from typing import Final

import gnupg

ENCRYPTED_FILE_DIR: Final[str] = os.environ.get("ENCRYPTED_FILE_DIR")
if not ENCRYPTED_FILE_DIR:
    raise ValueError("An \"ENCRYPTED_FILE_DIR\" for temporary storage of the encryption files is required, but was not found in the system environment variables.")


GPG_PASSPHRASE: Final[str] = os.environ.get("GPG_PASSPHRASE")
if not GPG_PASSPHRASE:
    raise ValueError("A \"GPG_PASSPHRASE\" for file encryption is required, but was not found in the system environment variables.")

logger = logging.getLogger("app.encrypt")

if not os.path.exists(ENCRYPTED_FILE_DIR):
    os.makedirs(ENCRYPTED_FILE_DIR, exist_ok=True)

def encrypt_and_compress_file(input_file_path: str, prepend_str = ""):
    """
    Compresses and encrypts a file using gzip and GPG.

    Args:
        input_file_path: Path to the input file.
        prepend_str: String to prepend to the encrypted .gz.gpg file.

    Returns:
        Path to the encrypted and compressed archive, or None on error.
    """
    with tempfile.TemporaryDirectory() as temp_dir:
        input_file_name = os.path.basename(input_file_path)
        
        # Create temporary file paths
        compressed_file_path = os.path.join(temp_dir, input_file_name + ".gz")
        encrypted_file_path = os.path.join(ENCRYPTED_FILE_DIR, prepend_str + input_file_name + ".gz.gpg")

        # Compress the input file
        logger.info(f"Compressing file: \"{input_file_path}\"")
        with open(input_file_path, "rb") as input_file, gzip.open(compressed_file_path, "wb") as compressed_file:
            while True:
                chunk = input_file.read(4096)  # Read in chunks
                if not chunk:
                    break
                compressed_file.write(chunk)
        logger.debug(f"Successfully compressed file to \"{compressed_file_path}\"")

        # Encrypt the compressed file
        logger.info(f"Encrypting file: \"{compressed_file_path}\"")
        gpg = gnupg.GPG()
        with open(compressed_file_path, "rb") as compressed_file:
            encrypted_data = gpg.encrypt_file(compressed_file, recipients=None, symmetric="AES256", passphrase=GPG_PASSPHRASE, output=encrypted_file_path)

        if encrypted_data.ok:
            # Remove only the compressed file
            os.remove(compressed_file_path)
            logger.debug(f"Successfully encrypted file to \"{encrypted_file_path}\"")
            return encrypted_file_path
        else:
            # Remove any potential intermediate files
            logger.error(f"Error while encrypting file: \"{compressed_file_path}\"")
            logger.info(f"Cleaning up intermediate files for \"{input_file}\"")
            if os.path.exists(compressed_file_path):
                os.remove(compressed_file_path)
                logger.info(f"Deleted compressed file: \"{compressed_file_path}\"")
            if os.path.exists(encrypted_file_path):
                os.remove(encrypted_file_path)
                logger.info(f"Deleted encrypted file: \"{encrypted_file_path}\"")
            raise Exception("GPG encryption failed")
