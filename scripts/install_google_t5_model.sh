echo "[Downloading Google t5xxl_fp8_e4m3fn Model...]"

mkdir -p /workspace/ComfyUI/models/clip/t5
huggingface-cli download mcmonkey/google_t5-v1_1-xxl_encoderonly t5xxl_fp8_e4m3fn.safetensors --local-dir /workspace/ComfyUI/models/clip/t5

echo "[Google t5xxl_fp8_e4m3fn Model downloaded.]"