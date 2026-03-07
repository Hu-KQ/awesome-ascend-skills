#!/bin/bash
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIR="/home/z00879328/01-projects/02-internal/01-pae/06-DiffusersSkills/test"
readonly CONDA_ENV="torch2.8_py310"

echo "=== Diffusers Weight Prep Validation ==="
echo "Test directory: $TEST_DIR"
echo "Conda environment: $CONDA_ENV"
echo ""

source ~/.bashrc
conda activate "$CONDA_ENV"

cd "$TEST_DIR"

echo "Step 1: Check required packages"
echo "--------------------------------"
python3 -c "import huggingface_hub; print(f'huggingface_hub: {huggingface_hub.__version__}')" || {
    echo "Installing huggingface_hub..."
    pip install -U huggingface_hub
}

python3 -c "import modelscope; print(f'modelscope: {modelscope.__version__}')" || {
    echo "Installing modelscope..."
    pip install modelscope
}

python3 -c "import torch; print(f'torch: {torch.__version__}')" || {
    echo "Error: PyTorch not found"
    exit 1
}

echo ""
echo "Step 2: Test download_weights.py (dry-run mode)"
echo "------------------------------------------------"

echo "Testing HuggingFace download (dry-run)..."
python3 "$SCRIPT_DIR/download_weights.py" hf Qwen/Qwen-Image-2512 --dry-run

echo ""
echo "Testing ModelScope download (dry-run)..."
python3 "$SCRIPT_DIR/download_weights.py" modelscope Wan-AI/Wan2.2-T2V-A14B --dry-run

echo ""
echo "Step 3: Test generate_fake_weights.py"
echo "--------------------------------------"

mkdir -p test_fake_weights

cat > test_config.json << 'EOF'
{
  "model_type": "bert",
  "hidden_size": 768,
  "num_hidden_layers": 12,
  "num_attention_heads": 12,
  "intermediate_size": 3072,
  "vocab_size": 30522
}
EOF

echo "Generating fake weights from test config..."
python3 "$SCRIPT_DIR/generate_fake_weights.py" test_config.json -o test_fake_weights

echo ""
echo "Verifying generated weights..."
python3 << 'PYEOF'
import torch
import os

weights_path = "test_fake_weights/pytorch_model.bin"
if not os.path.exists(weights_path):
    print(f"Error: {weights_path} not found")
    exit(1)

state_dict = torch.load(weights_path, map_location='cpu')
print(f"Loaded {len(state_dict)} tensors")
print(f"Total parameters: {sum(t.numel() for t in state_dict.values()):,}")

sample_keys = list(state_dict.keys())[:3]
print(f"\nSample keys: {sample_keys}")

for key in sample_keys:
    print(f"  {key}: {state_dict[key].shape}")

print("\n✅ Fake weights validation passed!")
PYEOF

echo ""
echo "Step 4: Cleanup"
echo "---------------"
rm -rf test_fake_weights test_config.json

echo ""
echo "=== All validations passed! ==="
