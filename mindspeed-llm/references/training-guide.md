# MindSpeed-LLM Training Configuration Guide

## Training Backends

MindSpeed-LLM supports two training backends:

| Backend | Entry Point | Best For |
|---------|-------------|----------|
| Megatron-Core (mcore) | `pretrain_gpt.py` / `posttrain_gpt.py` | Full-featured training with TP, PP, CP, VP parallelism |
| FSDP2 | `train_fsdp2.py` | Memory-efficient training with Fully Sharded Data Parallel |

---

## Megatron-Core Backend

### Pretraining

Entry point: `pretrain_gpt.py`

```bash
torchrun \
    --nproc_per_node 8 \
    --nnodes 1 \
    --master_addr localhost \
    --master_port 6000 \
    pretrain_gpt.py \
    --use-mcore-models \
    --tensor-model-parallel-size 1 \
    --pipeline-model-parallel-size 4 \
    --num-layers 32 \
    --hidden-size 4096 \
    --ffn-hidden-size 11008 \
    --num-attention-heads 32 \
    --seq-length 4096 \
    --micro-batch-size 2 \
    --global-batch-size 16 \
    --train-iters 5000 \
    --lr 3e-4 \
    --bf16 \
    --use-flash-attn \
    --tokenizer-type PretrainedFromHF \
    --tokenizer-name-or-path ./model_hf/ \
    --data-path ./pretrain_dataset/data_text_document \
    --split 98,2,0 \
    --load ./model_weights/ \
    --save ./output/ \
    --distributed-backend nccl
```

### Instruction Fine-Tuning (SFT)

Entry point: `posttrain_gpt.py`

**Full-parameter fine-tuning:**

```bash
torchrun \
    --nproc_per_node 8 \
    --nnodes 1 \
    --master_addr localhost \
    --master_port 6011 \
    posttrain_gpt.py \
    --use-mcore-models \
    --finetune \
    --stage sft \
    --is-instruction-dataset \
    --prompt-type qwen \
    --no-pad-to-seq-lengths \
    --padded-samples \
    --tensor-model-parallel-size 1 \
    --pipeline-model-parallel-size 4 \
    --num-layers 32 --hidden-size 4096 \
    --ffn-hidden-size 11008 --num-attention-heads 32 \
    --seq-length 4096 \
    --micro-batch-size 1 \
    --global-batch-size 8 \
    --train-iters 2000 \
    --lr 1e-5 \
    --bf16 \
    --use-flash-attn \
    --no-load-optim --no-load-rng \
    --data-path ./finetune_dataset/alpaca \
    --split 100,0,0 \
    --load ./model_weights/ \
    --save ./output/ \
    --distributed-backend nccl
```

**LoRA fine-tuning** (add these flags):

```bash
    --lora-r 8 \
    --lora-alpha 16 \
    --lora-fusion \
    --lora-target-modules linear_qkv linear_proj linear_fc1 linear_fc2
```

**QLoRA fine-tuning** (add these flags):

```bash
    --lora-r 8 \
    --lora-alpha 16 \
    --qlora \
    --lora-target-modules linear_qkv linear_proj linear_fc1 linear_fc2
```

---

## FSDP2 Backend

### Configuration (YAML)

```yaml
model:
  model_name_or_path: /path/to/model
  trust_remote_code: false

data:
  dataset:
    file_name: "/path/to/data"
  template: qwen3
  cutoff_len: 4096
  data_manager_type: mg

parallel:
  fsdp_size: 8
  fsdp_modules:
    - model.layers.{*}
  tp_size: 1
  recompute: true

training:
  stage: pt              # pt (pretraining) or sft (fine-tuning)
  per_device_train_batch_size: 1
  max_steps: 2000
  lr: 1e-05
  optimizer: adamw
  output_dir: ./output
```

### Launch

```bash
torchrun \
    --nproc_per_node 8 \
    --nnodes 1 \
    --master_addr localhost \
    --master_port 6000 \
    train_fsdp2.py examples/fsdp2/qwen3/pretrain_qwen3_8b_4k_fsdp2_A2.yaml
```

---

## Parallelism Strategy Guide

### Tensor Parallelism (TP)

Splits model layers across NPUs horizontally. Best for models where each layer is large.

```bash
--tensor-model-parallel-size 4   # Split each layer across 4 NPUs
```

### Pipeline Parallelism (PP)

Distributes model layers across NPUs vertically. Best when you have many layers.

```bash
--pipeline-model-parallel-size 4  # Distribute layers across 4 pipeline stages
```

### Context Parallelism (CP)

Splits long sequences across NPUs. For very long context training.

```bash
--context-parallel-size 2         # Split sequence across 2 NPUs
```

### Recommended Configurations

| Model Size | NPU Count | TP | PP | Notes |
|-----------|-----------|----|----|-------|
| 0.5B-3B | 8 | 1 | 1 | Single card is sufficient per replica |
| 7B | 8 | 1 | 2 | Or TP=2, PP=1 |
| 14B | 8 | 2 | 2 | |
| 32B | 8 | 4 | 2 | |
| 72B | 8 | 8 | 1 | Or TP=4, PP=2 on 16 NPUs |
| 72B | 16 | 4 | 4 | Two nodes |

**Constraint**: `TP * PP * CP <= total NPU count`. Remaining NPUs participate in data parallelism.

---

## Optimization Flags

### Always Recommended

```bash
--bf16                          # BFloat16 precision
--use-flash-attn                # Flash Attention
--use-fused-rmsnorm             # Fused RMSNorm kernel
--use-fused-rotary-pos-emb      # Fused RoPE
--use-fused-swiglu              # Fused SwiGLU activation
--overlap-grad-reduce           # Overlap gradient AllReduce with backward
--use-distributed-optimizer     # Shard optimizer states across NPUs
--no-masked-softmax-fusion      # Disable masked softmax (better for Ascend)
--attention-softmax-in-fp32     # FP32 attention softmax for stability
```

### Learning Rate Schedule

```bash
--lr 1e-5                       # Peak learning rate
--min-lr 1e-6                   # Minimum LR
--lr-decay-style cosine         # Cosine decay (recommended)
--lr-warmup-fraction 0.01       # 1% warmup
```

### Checkpoint Control

```bash
--save-interval 1000            # Save every 1000 iterations
--eval-interval 1000            # Evaluate every 1000 iterations
--log-interval 1                # Log every iteration
--log-throughput                 # Log throughput metrics
```

---

## Model Architecture Parameters

### Qwen2.5 Family

| Model | layers | hidden | ffn | heads | kv_heads | vocab |
|-------|--------|--------|-----|-------|----------|-------|
| 0.5B | 24 | 896 | 4864 | 14 | 2 | 151936 |
| 1.5B | 28 | 1536 | 8960 | 12 | 2 | 151936 |
| 3B | 36 | 2048 | 11008 | 16 | 2 | 151936 |
| 7B | 32 | 3584 | 18944 | 28 | 4 | 152064 |
| 14B | 48 | 5120 | 13824 | 40 | 8 | 152064 |
| 32B | 64 | 5120 | 27648 | 40 | 8 | 152064 |
| 72B | 80 | 8192 | 29568 | 64 | 8 | 152064 |

Common flags for Qwen:

```bash
--add-qkv-bias                  # Qwen uses QKV bias
--group-query-attention         # GQA enabled
--rotary-base 1000000           # RoPE base frequency
--normalization RMSNorm
--swiglu
--disable-bias-linear
```

### Prompt Types

| `--prompt-type` | Model Family |
|-----------------|-------------|
| `qwen` | Qwen2.5, Qwen2 |
| `qwen3` | Qwen3 |
| `llama3` | LLaMA 3, 3.1, 3.2 |
| `chatglm4` | ChatGLM4 |
| `deepseek3` | DeepSeek-V3 |
| `baichuan2` | Baichuan 2 |

---

## Multi-Node Training

### Environment Setup (Each Node)

```bash
export MASTER_ADDR=<node0_ip>
export MASTER_PORT=6000
export NNODES=2
export NODE_RANK=<0_or_1>
export NPUS_PER_NODE=8
```

### Launch Script Pattern

```bash
# Node 0
torchrun \
    --nproc_per_node 8 \
    --nnodes 2 \
    --node_rank 0 \
    --master_addr 192.168.1.10 \
    --master_port 6000 \
    posttrain_gpt.py [args...]

# Node 1
torchrun \
    --nproc_per_node 8 \
    --nnodes 2 \
    --node_rank 1 \
    --master_addr 192.168.1.10 \
    --master_port 6000 \
    posttrain_gpt.py [args...]
```

### Pre-Flight Checks for Multi-Node

1. All nodes can SSH to each other without password
2. CANN and torch_npu versions match across all nodes
3. HCCL communication works (test with [hccl-test](../../hccl-test/SKILL.md))
4. Model weights and data accessible from all nodes (shared storage or pre-copied)
