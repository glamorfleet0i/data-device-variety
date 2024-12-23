echo "[Downloading CogVideo-5b-I2V Model...]"

mkdir -p /workspace/ComfyUI/models/CogVideo/CogVideoX-5b-I2V

MODEL_FILES=(
    "scheduler/scheduler_config.json"
    "transformer/config.json"
    "transformer/diffusion_pytorch_model.safetensors.index.json"
    "transformer/diffusion_pytorch_model-00001-of-00003.safetensors"
    "transformer/diffusion_pytorch_model-00002-of-00003.safetensors"
    "transformer/diffusion_pytorch_model-00003-of-00003.safetensors"
    "vae/config.json"
    "vae/diffusion_pytorch_model.safetensors"
)
for file in "${MODEL_FILES[@]}"; do
    huggingface-cli download THUDM/CogVideoX-5b-I2V $file --local-dir /workspace/ComfyUI/models/CogVideo/CogVideoX-5b-I2V
done

echo "[CogVideo-5b-I2V Model downloaded.]"