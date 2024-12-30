REPOS=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/kijai/ComfyUI-CogVideoXWrapper.git"
    "https://github.com/liusida/ComfyUI-Login.git"
    "https://github.com/glamorfleet0i/ComfyUI-Firewall.git"
    "https://github.com/glamorfleet0i/ComfyUI-AutoStop.git"
)

echo "[Downloading ${#REPOS[@]} custom nodes...]"

cd /workspace/ComfyUI/custom_nodes

# Clone all necessary custom node repos in parallel
for repo in "${REPOS[@]}"; do
    git clone "$repo" &
done
wait

# Install the requirements for each cloned custom node
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    echo "[Installing custom node: $repo_name]"
    cd "/workspace/ComfyUI/custom_nodes/$(basename "$repo_name" .git)"
    pip install -r requirements.txt
done

echo "[Custom nodes successfully installed.]"