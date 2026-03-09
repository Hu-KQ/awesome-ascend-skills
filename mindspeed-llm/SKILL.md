---
name: mindspeed-llm
description: MindSpeed-LLM distributed training suite for LLM pretraining, instruction fine-tuning (full/LoRA/QLoRA), and evaluation on Huawei Ascend NPU. Covers environment setup (CANN + torch_npu + Megatron-LM), data preprocessing (Alpaca/ShareGPT), HF-to-Megatron weight conversion, and distributed launch with TP/PP/CP parallelism. Supports Qwen, LLaMA, DeepSeek, GLM, Mistral, Baichuan and more.
keywords:
    - mindspeed
    - mindspeed-llm
    - fine-tuning
    - 微调
    - lora
    - qlora
    - sft
    - pretraining
    - 预训练
    - megatron
    - distributed training
    - 分布式训练
    - ascend npu
    - weight conversion
    - 权重转换
    - instruction tuning
    - 指令微调
    - qwen
    - llama
    - deepseek
---

# MindSpeed-LLM - Distributed LLM Training on Ascend NPU

MindSpeed-LLM is a distributed training suite for large language models built on the Ascend ecosystem. It provides end-to-end solutions for pretraining, instruction fine-tuning (SFT/LoRA/QLoRA), online inference, model evaluation, and weight conversion.

**Repository**: https://gitcode.com/ascend/MindSpeed-LLM

---

## Quick Start

### LoRA Fine-Tuning (Qwen2.5-7B)

```bash
# 1. Preprocess instruction data
python preprocess_data.py \
    --input ./dataset/alpaca.parquet \
    --tokenizer-name-or-path ./model_from_hf/Qwen2.5-7B-Instruct/ \
    --output-prefix ./finetune_dataset/alpaca \
    --handler-name AlpacaStyleInstructionHandler \
    --tokenizer-type PretrainedFromHF \
    --workers 4 \
    --prompt-type qwen

# 2. Convert HF weights to Megatron format
python convert_ckpt.py \
    --use-mcore-models --model-type GPT \
    --load-model-type hf --save-model-type mg \
    --target-tensor-parallel-size 1 \
    --target-pipeline-parallel-size 4 \
    --add-qkv-bias \
    --load-dir ./model_from_hf/Qwen2.5-7B-Instruct/ \
    --save-dir ./model_weights/qwen25_7b_mcore/ \
    --tokenizer-model ./model_from_hf/Qwen2.5-7B-Instruct/tokenizer.json \
    --model-type-hf llama2 --params-dtype bf16

# 3. Launch fine-tuning (uses example script)
bash examples/mcore/qwen25/tune_qwen25_7b_4k_lora_ptd.sh
```

### Pretraining (Qwen2.5-7B)

```bash
# Data preprocessing
python preprocess_data.py \
    --input ./dataset/raw_data.parquet \
    --tokenizer-name-or-path ./model_from_hf/Qwen2.5-7B/ \
    --output-prefix ./pretrain_dataset/data \
    --tokenizer-type PretrainedFromHF \
    --workers 4

# Launch pretraining
bash examples/mcore/qwen25/pretrain_qwen25_7b_32k_ptd.sh
```

---

## Environment Setup

### Prerequisites

| Component | Version | Notes |
|-----------|---------|-------|
| CANN | 8.5.0+ | `source /usr/local/Ascend/ascend-toolkit/set_env.sh` |
| Python | 3.10 / 3.11 | |
| PyTorch | 2.7.1 | `pip install torch==2.7.1 --index-url https://download.pytorch.org/whl/cpu` |
| torch_npu | 2.7.1 | `pip install torch_npu==2.7.1` |
| Megatron-LM | core_v0.12.1 | Copy `megatron/` module into MindSpeed-LLM directory |
| MindSpeed | master | `pip install -e .` from MindSpeed repo |

### Installation Steps

```bash
# 1. Set Ascend environment
source /usr/local/Ascend/ascend-toolkit/set_env.sh
source /usr/local/Ascend/nnal/atb/set_env.sh

# 2. Install MindSpeed (acceleration library)
git clone https://gitcode.com/ascend/MindSpeed.git
cd MindSpeed && pip install -r requirements.txt && pip install -e .
cd ..

# 3. Clone Megatron-LM and copy module
git clone https://github.com/NVIDIA/Megatron-LM.git
cd Megatron-LM && git checkout core_v0.12.1 && cd ..
cp -r Megatron-LM/megatron MindSpeed-LLM/

# 4. Install MindSpeed-LLM
cd MindSpeed-LLM
pip install -r requirements.txt
```

### Verify Installation

```bash
python -c "
import torch
import torch_npu
print(f'NPUs available: {torch_npu.npu.device_count()}')
print(f'NPU ready: {torch.npu.is_available()}')
"
```

---

## Training Pipeline

The standard workflow has three stages: **data preprocessing** -> **weight conversion** -> **training launch**.

### Entry Points

| Entry Point | Use For |
|-------------|---------|
| `pretrain_gpt.py` | Pretraining from scratch or continued pretraining |
| `posttrain_gpt.py` | **Instruction fine-tuning (SFT, LoRA, QLoRA, full)** |
| `posttrain_gpt.py` | Post-training (DPO, GRPO) |
| `train_fsdp2.py` | FSDP2 backend training |

> **Important**: All fine-tuning tasks (full, LoRA, QLoRA) use `posttrain_gpt.py`, NOT `pretrain_gpt.py`. The `posttrain_gpt.py` entry point correctly routes `--is-instruction-dataset` to the packed instruction data loader.

### Example Scripts

Scripts are located in `examples/mcore/<model_name>/`:

| Script Pattern | Purpose |
|----------------|---------|
| `data_convert_<model>_pretrain.sh` | Pretraining data preprocessing |
| `data_convert_<model>_instruction.sh` | Instruction data preprocessing |
| `ckpt_convert_<model>_hf2mcore.sh` | HF to Megatron weight conversion |
| `ckpt_convert_<model>_mcore2hf.sh` | Megatron to HF weight conversion |
| `pretrain_<model>_*.sh` | Pretraining launch scripts |
| `tune_<model>_*_full*.sh` | Full-parameter fine-tuning |
| `tune_<model>_*_lora*.sh` | LoRA fine-tuning |
| `generate_<model>_*.sh` | Inference scripts |
| `evaluate_<model>_*.sh` | Evaluation scripts |

---

## Data Preprocessing

### Instruction Data (Alpaca Format)

```bash
python preprocess_data.py \
    --input ./dataset/train.parquet \
    --tokenizer-name-or-path ./model_hf/ \
    --output-prefix ./finetune_dataset/alpaca \
    --handler-name AlpacaStyleInstructionHandler \
    --tokenizer-type PretrainedFromHF \
    --workers 4 \
    --prompt-type qwen
```

### Instruction Data (ShareGPT Format)

```bash
python preprocess_data.py \
    --input ./dataset/sharegpt.jsonl \
    --tokenizer-name-or-path ./model_hf/ \
    --output-prefix ./finetune_dataset/sharegpt \
    --handler-name SharegptStyleInstructionHandler \
    --tokenizer-type PretrainedFromHF \
    --workers 4 \
    --prompt-type qwen
```

### Pretraining Data

```bash
python preprocess_data.py \
    --input ./dataset/raw_text.parquet \
    --tokenizer-name-or-path ./model_hf/ \
    --output-prefix ./pretrain_dataset/data \
    --tokenizer-type PretrainedFromHF \
    --workers 4 \
    --log-interval 1000
```

### Data Handlers

| Handler | Input Format | Use For |
|---------|--------------|---------|
| `GeneralPretrainHandler` | Text with `"text"` field | Pretraining |
| `AlpacaStyleInstructionHandler` | `instruction` + `output` fields | SFT (single-turn) |
| `SharegptStyleInstructionHandler` | Multi-turn conversation | SFT (multi-turn) |
| `AlpacaStylePairwiseHandler` | Chosen + rejected pairs | DPO training |

### Output Files

Instruction preprocessing generates packed files:

```
<prefix>_packed_input_ids_document.bin / .idx
<prefix>_packed_labels_document.bin / .idx
<prefix>_packed_attention_mask_document.bin / .idx
```

The `--data-path` argument should point to `<prefix>` (without `_packed`). The data loader (`get_packed_indexed_dataset`) appends `_packed_*_document` automatically.

---

## Weight Conversion

### HuggingFace -> Megatron

```bash
python convert_ckpt.py \
    --use-mcore-models \
    --model-type GPT \
    --load-model-type hf \
    --save-model-type mg \
    --target-tensor-parallel-size <TP> \
    --target-pipeline-parallel-size <PP> \
    --add-qkv-bias \
    --load-dir ./model_hf/ \
    --save-dir ./model_mg/ \
    --tokenizer-model ./model_hf/tokenizer.json \
    --model-type-hf llama2 \
    --params-dtype bf16
```

### Megatron -> HuggingFace

```bash
python convert_ckpt.py \
    --use-mcore-models \
    --model-type GPT \
    --load-model-type mg \
    --save-model-type hf \
    --load-dir ./model_mg/ \
    --save-dir ./model_hf_output/ \
    --tokenizer-model ./model_hf/tokenizer.json \
    --params-dtype bf16
```

### LoRA Weight Merging

```bash
python convert_ckpt.py \
    --use-mcore-models \
    --model-type GPT \
    --load-model-type mg \
    --save-model-type hf \
    --load-dir ./lora_output/ \
    --save-dir ./merged_hf/ \
    --lora-load ./lora_output/ \
    --tokenizer-model ./model_hf/tokenizer.json
```

> For very large models, use `convert_ckpt_v2.py` which has optimized memory handling.

---

## Fine-Tuning Configuration

### LoRA Parameters

```bash
--lora-r 8                    # LoRA rank (typical: 8-16)
--lora-alpha 16               # LoRA scaling factor
--lora-fusion                 # Enable CCLoRA (computation-communication overlap)
--lora-target-modules linear_qkv linear_proj linear_fc1 linear_fc2
```

### Common Training Parameters

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| `--tensor-model-parallel-size` | Tensor parallelism degree | 1-8 |
| `--pipeline-model-parallel-size` | Pipeline parallelism degree | 1-8 |
| `--micro-batch-size` | Micro batch per NPU | 1-4 |
| `--global-batch-size` | Total batch across all NPUs | 8-64 |
| `--seq-length` | Sequence length | 2048-32768 |
| `--train-iters` | Training iterations | 1000-5000 |
| `--lr` | Learning rate | 1e-5 ~ 1e-6 |
| `--bf16` | BFloat16 precision | Always recommended |
| `--use-flash-attn` | Flash Attention | Always recommended |
| `--use-fused-rmsnorm` | Fused RMSNorm kernel | Always recommended |
| `--use-fused-swiglu` | Fused SwiGLU kernel | Always recommended |
| `--use-distributed-optimizer` | Distributed optimizer | Recommended for multi-NPU |

### Fine-Tuning Flags

```bash
--finetune                    # Enable fine-tuning mode
--stage sft                   # Supervised fine-tuning stage
--is-instruction-dataset      # Use packed instruction data loader
--prompt-type qwen            # Chat template (qwen, qwen25, llama3, etc.)
--no-load-optim               # Don't load optimizer state from checkpoint
--no-load-rng                 # Don't load RNG state
```

---

## Supported Models

### Dense Models

| Model Family | Sizes | Example Script Directory |
|-------------|-------|--------------------------|
| Qwen2.5 | 0.5B, 1.5B, 3B, 7B, 14B, 32B, 72B | `examples/mcore/qwen25/` |
| Qwen3 | 0.6B, 1.7B, 4B, 8B, 14B, 30B, 32B | `examples/mcore/qwen3/` |
| LLaMA 3/3.1 | 8B, 70B | `examples/mcore/llama3/` |
| DeepSeek-V2/V3 | Various | `examples/mcore/deepseek/` |
| ChatGLM4 | 9B | `examples/mcore/glm4/` |
| Mistral | 7B | `examples/mcore/mistral/` |
| Baichuan2 | 7B, 13B | `examples/mcore/baichuan2/` |

### MoE Models

| Model | Example Directory |
|-------|-------------------|
| Qwen3-MoE | `examples/mcore/qwen3_moe/` |
| DeepSeek-V2 MoE | `examples/mcore/deepseek2/` |
| Mixtral 8x7B | `examples/mcore/mixtral/` |

---

## Troubleshooting

**Q: `AssertionError: .idx and .bin files cannot be found`**

This error has two common causes:

1. **Wrong entry point**: Use `posttrain_gpt.py` (not `pretrain_gpt.py`) for instruction fine-tuning. Only `posttrain_gpt.py` supports the packed instruction data format.
2. **Wrong data path**: For instruction datasets, `--data-path` should be the prefix **without** `_packed`. The loader appends `_packed_*_document` automatically.

```bash
# Correct: prefix only
--data-path ./finetune_dataset/alpaca

# Wrong: includes _packed
--data-path ./finetune_dataset/alpaca_packed
```

**Q: `$'\r': command not found` when running scripts**

The training script has Windows line endings (CRLF). Fix with:

```bash
sed -i "s/\r//g" your_script.sh
```

**Q: `ModuleNotFoundError: No module named 'yaml'` on torch_npu import**

The CANN Docker image may lack basic Python packages. Install them:

```bash
pip install numpy pyyaml scipy
```

**Q: Training hangs or HCCL timeout**

```bash
# Increase HCCL timeout
export HCCL_CONNECT_TIMEOUT=1800

# Set device connections
export CUDA_DEVICE_MAX_CONNECTIONS=1
```

**Q: How to choose TP/PP for my model?**

| Model Size | NPUs | Recommended |
|-----------|------|-------------|
| < 3B | 1-8 | TP=1, PP=1 |
| 7B-14B | 8 | TP=1-2, PP=1-4 |
| 32B-72B | 8-16 | TP=4-8, PP=2-4 |
| 100B+ | 16+ | TP=8, PP=4+ |

---

## References

- [references/installation.md](references/installation.md) - Detailed installation and environment setup
- [references/training-guide.md](references/training-guide.md) - Training configuration deep dive and FSDP2 backend

---

## Related Skills

- [ascend-docker](../ascend-docker/SKILL.md) - Docker container setup for Ascend NPU
- [torch_npu](../torch_npu/SKILL.md) - PyTorch Ascend extension (torch_npu)
- [msmodelslim](../msmodelslim/SKILL.md) - Model quantization before fine-tuning
- [vllm-ascend](../vllm-ascend/SKILL.md) - Inference serving after fine-tuning
- [hccl-test](../hccl-test/SKILL.md) - HCCL communication testing for multi-NPU

---

## Official References

- **MindSpeed-LLM Repository**: https://gitcode.com/ascend/MindSpeed-LLM
- **MindSpeed Repository**: https://gitcode.com/ascend/MindSpeed
- **Megatron-LM**: https://github.com/NVIDIA/Megatron-LM
- **Huawei Ascend Documentation**: https://www.hiascend.com/document
