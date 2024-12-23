echo "[Installing ComfyUI...]"

cd /workspace
git clone https://github.com/comfyanonymous/ComfyUI.git
cd /workspace/ComfyUI
pip install -r requirements.txt

echo "[ComfyUI successfully installed.]"