FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Update system and install openssh
RUN apt-get update && apt-get full-upgrade -y && apt-get install openssh-server -y

# Set up ssh access
RUN mkdir -p ~/.ssh

# Install dependencies
RUN pip install "huggingface_hub[cli]" hf-transfer sageattention
RUN pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu124

# Initialize workspace directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Install ComfyUI
COPY scripts/install_comfyui.sh /workspace/setup/install_comfyui.sh
RUN chmod +x /workspace/setup/install_comfyui.sh
RUN /workspace/setup/install_comfyui.sh

# Install ComfyUI Custom Nodes
COPY scripts/install_custom_nodes.sh /workspace/setup/install_custom_nodes.sh
RUN chmod +x /workspace/setup/install_custom_nodes.sh
RUN /workspace/setup/install_custom_nodes.sh

# Download Google T5 model
COPY scripts/install_google_t5_model.sh /workspace/setup/install_google_t5_model.sh
RUN chmod +x /workspace/setup/install_google_t5_model.sh
RUN /workspace/setup/install_google_t5_model.sh

# Download CogVideo-5b-I2V Model
COPY scripts/install_cogvideo_model.sh /workspace/setup/install_cogvideo_model.sh
RUN chmod +x /workspace/setup/install_cogvideo_model.sh
RUN /workspace/setup/install_cogvideo_model.sh

# Download CogVideo Penetration LoRA
COPY scripts/install_cogvideo_lora.sh /workspace/setup/install_cogvideo_lora.sh
RUN chmod +x /workspace/setup/install_cogvideo_lora.sh
RUN /workspace/setup/install_cogvideo_lora.sh

# Install ComfyUI Filen Sync
COPY services/ComfyUI-Filen-Sync /workspace/services/ComfyUI-Filen-Sync
WORKDIR /workspace/services/ComfyUI-Filen-Sync
RUN pip install -r requirements.txt

# Add startup script
COPY scripts/start.sh /workspace/start.sh

# Purge pip cache before shipping
RUN pip cache purge

WORKDIR /workspace
EXPOSE 3000
CMD ["/bin/bash", "/workspace/start.sh"]