# Custom node repos to install
REPOS=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/kijai/ComfyUI-CogVideoXWrapper.git"
    "https://github.com/liusida/ComfyUI-Login.git"
)


export HF_HUB_ENABLE_HF_TRANSFER=1

# 1. Install Global Dependencies
echo "[Installing dependencies...]"
pip install "huggingface_hub[cli]" hf-transfer
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu124

mkdir -p /workspace

# 2. Install ComfyUI if not already installed
if [ ! -d "/workspace/ComfyUI" ]; then
    echo "[Installing ComfyUI...]"
    git clone https://github.com/comfyanonymous/ComfyUI.git
    cd /workspace/ComfyUI
    pwd
    pip install -r requirements.txt
fi

# 3. Download and install ComfyUI Custom Nodes
cd /workspace/ComfyUI/custom_nodes
pwd

echo "[Downloading ${#REPOS[@]} custom nodes...]"

# 3a. Clone all necessary custom node repos in parallel
for repo in "${REPOS[@]}"; do
    git clone "$repo" &
done
wait

# 3b. Install the requirements for each cloned custom node
for repo in "${REPOS[@]}"; do
    echo "[Installing custom node: $repo...]"
    repo_name=$(basename "$repo" .git)
    cd "/workspace/ComfyUI/custom_nodes/$(basename "$repo_name" .git)"
    pwd
    pip install -r requirements.txt
done

# 3c. Create ComfyUI-Login directory to hold credentials
mkdir -p /workspace/ComfyUI/login

# 4. Download necessary models
# 4a. Download Google T5 Model
mkdir -p /workspace/ComfyUI/models/clip/t5
cd /workspace/ComfyUI/models/clip/t5
pwd
if [ ! -f "/workspace/ComfyUI/models/clip/t5/t5xxl_fp8_e4m3fn.safetensors" ]; then
    echo "[Downloading Google t5xxl_fp8_e4m3fn Model...]"
    model_path=$(huggingface-cli download mcmonkey/google_t5-v1_1-xxl_encoderonly t5xxl_fp8_e4m3fn.safetensors)
    cp $model_path /workspace/ComfyUI/models/clip/t5
fi

# 4b. Download CogVideo Penetration LoRA Model
mkdir -p /workspace/ComfyUI/models/CogVideo/loras/
cd /workspace/ComfyUI/models/CogVideo/loras/
pwd
if [ ! -f "/workspace/ComfyUI/models/CogVideo/loras/penetration-5000.safetensors" ]; then
    echo "[Downloading CogVideo Penetration LoRA...]"
    curl -LJO "https://civitai.com/api/download/models/1068885?type=Model&format=SafeTensor"
fi

echo "[Setup complete!]"
