FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
ENV HF_HUB_ENABLE_HF_TRANSFER=1

RUN apt-get update && apt-get full-upgrade -y

WORKDIR /workspace
COPY setup.sh /workspace/setup.sh
RUN chmod +x /workspace/setup.sh
RUN /workspace/setup.sh

WORKDIR /workspace/ComfyUI
CMD ["python", "main.py", "--listen=0.0.0.0", "--port=3000"]
