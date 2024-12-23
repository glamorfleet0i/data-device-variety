#!/bin/bash

# Read password hash from $COMFY_LOGIN_PASSWORD_HASH if it isnt blank and write to the file "/workspace/ComfyUI/login/PASSWORD"
if [ ! -z "$COMFY_LOGIN_PASSWORD_HASH" ]; then
    mkdir -p /workspace/ComfyUI/login
    echo $COMFY_LOGIN_PASSWORD_HASH > /workspace/ComfyUI/login/PASSWORD
    echo "[PASSWORD hash for ComfyUI-Login found and added.]"
fi

echo "[Starting ComfyUI...]"
python /workspace/ComfyUI/main.py --listen=0.0.0.0 --port=3000