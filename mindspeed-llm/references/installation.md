# MindSpeed-LLM Installation Guide

## Version Compatibility Matrix

| MindSpeed-LLM | MindSpeed | PyTorch | torch_npu | Megatron-LM | CANN |
|----------------|-----------|---------|-----------|-------------|------|
| master | master | 2.7.1 | latest | core_v0.12.1 | 8.5.0+ |
| 2.3.0 | 2.3.0_core_r0.12.1 | 2.7.1 | 7.3.0 | core_v0.12.1 | 8.5.0 |
| 2.2.0 | 2.2.0_core_r0.12.1 | 2.7.1 | 7.2.0 | core_v0.12.1 | 8.3.0+ |

---

## Docker-Based Setup (Recommended)

### Create Ascend Container

```bash
docker run -dit \
    --name mindspeed-llm \
    --network host \
    --privileged \
    --shm-size 64g \
    --device /dev/davinci0 \
    --device /dev/davinci1 \
    --device /dev/davinci2 \
    --device /dev/davinci3 \
    --device /dev/davinci4 \
    --device /dev/davinci5 \
    --device /dev/davinci6 \
    --device /dev/davinci7 \
    --device /dev/davinci_manager \
    -v /usr/local/dcmi:/usr/local/dcmi \
    -v /usr/local/bin/npu-smi:/usr/local/bin/npu-smi \
    -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    -v /home/workspace:/home/workspace \
    swr.cn-south-1.myhuaweicloud.com/ascendhub/cann:8.5.0-910b-ubuntu22.04-py3.11 \
    bash
```

Key parameters:
- `--shm-size 64g`: Shared memory for distributed training HCCL communication
- `--device /dev/davinci*`: Map NPU devices (adjust count for your hardware)
- `-v /usr/local/Ascend/driver`: Mount host Ascend driver

### Verify NPU Access in Container

```bash
npu-smi info -l    # Should show all NPU devices
```

---

## Step-by-Step Installation

### Step 1: Set Ascend Environment

```bash
source /usr/local/Ascend/ascend-toolkit/set_env.sh
source /usr/local/Ascend/nnal/atb/set_env.sh
```

Add these to `~/.bashrc` for persistence:

```bash
echo 'source /usr/local/Ascend/ascend-toolkit/set_env.sh' >> ~/.bashrc
echo 'source /usr/local/Ascend/nnal/atb/set_env.sh' >> ~/.bashrc
```

### Step 2: Install PyTorch and torch_npu

```bash
# PyTorch (CPU wheel, torch_npu provides the NPU backend)
pip install torch==2.7.1 --index-url https://download.pytorch.org/whl/cpu

# torch_npu (must match PyTorch version)
pip install torch_npu==2.7.1
```

Verify:

```bash
python -c "
import torch
import torch_npu
print(f'torch: {torch.__version__}')
print(f'torch_npu: {torch_npu.__version__}')
print(f'NPU count: {torch_npu.npu.device_count()}')
print(f'NPU available: {torch.npu.is_available()}')
"
```

> **Common issue**: If `import torch_npu` fails with `No module named 'yaml'`, install missing base packages: `pip install numpy pyyaml scipy`

### Step 3: Install MindSpeed

```bash
git clone https://gitcode.com/ascend/MindSpeed.git
cd MindSpeed
git checkout master    # or specific version tag
pip install -r requirements.txt
pip install -e .
cd ..
```

### Step 4: Prepare Megatron-LM

MindSpeed-LLM requires the Megatron-LM `megatron/` module to be present in its directory:

```bash
git clone https://github.com/NVIDIA/Megatron-LM.git
cd Megatron-LM
git checkout core_v0.12.1
cd ..

# Copy the megatron module into MindSpeed-LLM
cp -r Megatron-LM/megatron MindSpeed-LLM/
```

### Step 5: Install MindSpeed-LLM

```bash
cd MindSpeed-LLM
pip install -r requirements.txt
```

Key dependencies installed by requirements.txt:
- `transformers==4.57.1`
- `datasets>=2.16.0`
- `peft==0.7.1` (for LoRA/QLoRA)
- `accelerate`
- `ray==2.10.0`
- `triton-ascend`

---

## Directory Layout After Installation

```
/home/workspace/
├── MindSpeed/                    # Acceleration library
├── Megatron-LM/                  # Megatron source (for reference)
├── MindSpeed-LLM/                # Main training suite
│   ├── megatron/                 # Copied from Megatron-LM
│   ├── mindspeed_llm/            # Core codebase
│   ├── examples/                 # Training script templates
│   │   ├── mcore/                # Megatron-core backend
│   │   │   ├── qwen25/
│   │   │   ├── qwen3/
│   │   │   ├── llama3/
│   │   │   └── ...
│   │   └── fsdp2/                # FSDP2 backend
│   ├── configs/                  # Configuration files
│   ├── pretrain_gpt.py           # Pretraining entry
│   ├── posttrain_gpt.py          # Fine-tuning entry
│   ├── convert_ckpt.py           # Weight conversion
│   ├── preprocess_data.py        # Data preprocessing
│   └── ...
├── model_from_hf/                # HuggingFace model weights
├── model_weights/                # Converted Megatron weights
├── dataset/                      # Raw datasets
└── finetune_dataset/             # Preprocessed datasets
```

---

## Environment Variables

```bash
# Required for distributed training
export CUDA_DEVICE_MAX_CONNECTIONS=1
export HCCL_CONNECT_TIMEOUT=1800

# Optional performance tuning
export STREAMS_PER_DEVICE=32
```

---

## Troubleshooting Installation

**Q: `torch_npu` import fails with missing modules**

```bash
# Install commonly missing dependencies
pip install numpy pyyaml scipy attrs decorator psutil
```

**Q: Megatron module import errors**

Ensure you copied the `megatron/` directory (not cloned as a subdirectory):

```bash
ls MindSpeed-LLM/megatron/core/    # Should exist
ls MindSpeed-LLM/megatron/training/ # Should exist
```

**Q: CANN environment not found**

```bash
# Check CANN installation
ls /usr/local/Ascend/
# Should contain: ascend-toolkit, cann, cann-8.5.0, driver, nnal

# Find set_env.sh
find /usr/local/Ascend -name set_env.sh -maxdepth 3
```

**Q: Network issues when cloning repos**

If behind a proxy, configure git and pip:

```bash
export http_proxy=http://<proxy_host>:<port>
export https_proxy=http://<proxy_host>:<port>
git config --global http.proxy $http_proxy
```
