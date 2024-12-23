echo "[Downloading CogVideo Penetration LoRA...]"

mkdir -p /workspace/ComfyUI/models/CogVideo/loras/
cd /workspace/ComfyUI/models/CogVideo/loras/
curl -LJO "https://civitai.com/api/download/models/1068885?type=Model&format=SafeTensor"

echo "[CogVideo Penetration LoRA downloaded.]"