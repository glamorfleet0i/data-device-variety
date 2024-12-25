#!/bin/bash

echo "[Initializing system...]"

# Generate system host keys if not already present
host_key_files=(
    /etc/ssh/ssh_host_rsa_key
    /etc/ssh/ssh_host_ecdsa_key
    /etc/ssh/ssh_host_ed25519_key
)

for file in "${host_key_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "[Generating SSH Host Keys...]"
        ssh-keygen -A
        if [[ $? -eq 0 ]]; then # Ensure successful key generation
            echo "[SSH Host Keys successfully generated.]"
        else
            echo "[Error generating SSH Host Keys! Exiting...]"
            exit 1
        fi
        break
    fi
done

# Add user SSH public key to authorized_keys if not already present
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if ! grep -qF "$PUBLIC_KEY" ~/.ssh/authorized_keys; then
  echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  echo "[Added user SSH public key to authorized_keys.]"
fi

# Start sshd
service ssh start

# Start ComfyUI-Filen-Sync in the background
echo "[Starting ComfyUI Filen Sync...]"
python /workspace/services/ComfyUI-Filen-Sync/main.py &

# Read password hash from $COMFY_LOGIN_PASSWORD_HASH if it isn't blank and write to the file "/workspace/ComfyUI/login/PASSWORD"
if [ ! -z "$COMFY_LOGIN_PASSWORD_HASH" ]; then
    mkdir -p /workspace/ComfyUI/login
    echo $COMFY_LOGIN_PASSWORD_HASH > /workspace/ComfyUI/login/PASSWORD
    echo "[PASSWORD hash for ComfyUI-Login found and added.]"
fi

# Start ComfyUI
echo "[Starting ComfyUI...]"
python /workspace/ComfyUI/main.py --listen=0.0.0.0 --port=3000 &

echo "[Ready!]"

# Check GPU power limits
echo "[Verifying GPU power limits...]"

nvidia-smi

declare -A GPU_MIN_POWER_LIMITS=(
    ["NVIDIA GeForce RTX 4090"]="450"
    ["NVIDIA GeForce RTX 4080"]="320"
    ["NVIDIA GeForce RTX 4080 SUPER"]="320"
    ["NVIDIA GeForce RTX 3090"]="350"
)

gpu_model=$(nvidia-smi --query-gpu=name --format=csv,noheader --id=0) # Returns key
raw_power_limit=$(nvidia-smi --query-gpu=power.limit --format=csv,noheader --id=0) # Returns value in the format "200.00 W"
actual_power_limit=$(echo "$raw_power_limit" | sed 's/ W//' | cut -d'.' -f1)

if [[ ${GPU_MIN_POWER_LIMITS["$gpu_model"]+x} ]]; then
    expected_power_limit=${GPU_MIN_POWER_LIMITS["$gpu_model"]}
    if [[ "$actual_power_limit" -lt "$expected_power_limit" ]]; then
        echo "!!!!!!!!!!!!!!!"
        echo "[ERROR: '$gpu_model' should draw up to $expected_power_limit W, but is power limited at $actual_power_limit W. Performance will be impacted, please terminate and re-deploy the pod!]"
        echo "!!!!!!!!!!!!!!!"
    else
        echo "[OK: '$gpu_model' can draw up to $actual_power_limit W, expected at least $expected_power_limit W.]"
    fi
else
    echo "[WARNING: '$gpu_model' is not in the list of known GPUs. It is currently configured to draw up to $actual_power_limit W. Double-check to ensure this is the expected power draw.]"
fi

while true; do
    gpu_model=$(nvidia-smi --query-gpu=name --format=csv,noheader --id=0) # Returns key
    raw_power_limit=$(nvidia-smi --query-gpu=power.limit --format=csv,noheader --id=0) # Returns value in the format "200.00 W"
    actual_power_limit=$(echo "$raw_power_limit" | sed 's/ W//' | cut -d'.' -f1)

    if [[ ${GPU_MIN_POWER_LIMITS["$gpu_model"]+x} ]]; then
        expected_power_limit=${GPU_MIN_POWER_LIMITS["$gpu_model"]}
        if [[ "$actual_power_limit" -lt "$expected_power_limit" ]]; then
            echo "[ERROR: '$gpu_model' should draw up to $expected_power_limit W, but is power limited at $actual_power_limit W. Performance will be impacted, please change hosts by terminating and re-deploying the pod!]"
        fi
    else
        break
    fi
    
    sleep 15
done &

sleep infinity