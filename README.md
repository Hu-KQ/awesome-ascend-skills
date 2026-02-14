# Awesome Ascend Skills

A comprehensive knowledge base for Huawei Ascend NPU development, structured as distributed Claude Skills.

---

## For AI Agents

**If you are an AI agent reading this repository:**

Welcome! This is a Skill library for Ascend NPU development. Here's how to install and use these skills:

### How to Install These Skills

Choose your AI tool:

#### Claude Code

**Method 1: Plugin Marketplace (Recommended)**

```bash
# Register this repository
/plugin marketplace add awesome-ascend-skills

# Install all skills
/plugin install ascend-npu@awesome-ascend-skills

# Or install individually
/plugin install ascend-basic-env@awesome-ascend-skills
/plugin install ascend-dev@awesome-ascend-skills
```

**Method 2: Direct Copy**

```bash
# Copy to Claude Code skills directory
cp -r ascend-npu ~/.claude/skills/
cp -r ascend-basic-env ~/.claude/skills/
cp -r ascend-dev ~/.claude/skills/
cp -r ascend-use-cases ~/.claude/skills/
cp -r ascend-utils ~/.claude/skills/
```

**Method 3: Project-Local**

```
your-project/
├── .claude-skills/
│   ├── ascend-npu/
│   ├── ascend-basic-env/
│   └── ...
└── your-code/
```

#### OpenCode

OpenCode uses the same Agent Skills format as Claude Code.

**Method 1: Auto-Discovery (Recommended)**

OpenCode automatically discovers skills in the `.opencode/skills/` directory:

```bash
# Create skills directory
mkdir -p .opencode/skills

# Link or copy skills
cp -r /path/to/awesome-ascend-skills/ascend-npu .opencode/skills/
cp -r /path/to/awesome-ascend-skills/ascend-basic-env .opencode/skills/
cp -r /path/to/awesome-ascend-skills/ascend-dev .opencode/skills/
cp -r /path/to/awesome-ascend-skills/ascend-use-cases .opencode/skills/
cp -r /path/to/awesome-ascend-skills/ascend-utils .opencode/skills/
```

**Method 2: Global Skills Directory**

```bash
# Copy to OpenCode global skills directory
cp -r ascend-npu ~/.opencode/skills/
cp -r ascend-basic-env ~/.opencode/skills/
cp -r ascend-dev ~/.opencode/skills/
```

#### Codex (GitHub Copilot Chat / VS Code)

Codex uses system prompts and custom instructions.

**Method 1: VS Code Settings**

Add to `.vscode/settings.json`:

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "text": "You are an expert in Huawei Ascend NPU development. Reference the skills in .github/copilot/skills/ when answering questions about CANN, torch-npu, MindSpore, or vLLM Ascend."
    }
  ]
}
```

Then copy skills:

```bash
mkdir -p .github/copilot/skills
cp -r /path/to/awesome-ascend-skills/ascend-npu .github/copilot/skills/
cp -r /path/to/awesome-ascend-skills/ascend-basic-env .github/copilot/skills/
# ... copy other skills
```

**Method 2: Prompt Files**

Create `.github/copilot/prompts/ascend-npu.prompt.md`:

```markdown
---
description: Huawei Ascend NPU development expert
---

# Ascend NPU Development Guide

You are an expert in Huawei Ascend NPU development.

## Key Resources

- CANN Installation: See ascend-basic-env/cann-install/SKILL.md
- VLLM Deployment: See ascend-dev/frameworks/inference/vllm/SKILL.md
- Training: See ascend-dev/frameworks/training/
- Operators: See ascend-dev/operators/

## Best Practices

1. Always check environment with ascend-utils/scripts/
2. Follow official documentation for version-specific details
3. Use docker for consistent environments
```

#### Cursor

Cursor uses `.cursorrules` files and AI rules.

**Method 1: .cursorrules File**

Create `.cursorrules` in your project root:

```
You are an AI assistant specialized in Huawei Ascend NPU development.

When users ask about:
- Environment setup → reference ascend-basic-env/
- CANN installation → ascend-basic-env/cann-install/
- VLLM deployment → ascend-dev/frameworks/inference/vllm/
- Training frameworks → ascend-dev/frameworks/training/
- Custom operators → ascend-dev/operators/

Always check the SKILL.md files for detailed instructions.

Official docs:
- https://www.hiascend.com/document
- https://docs.vllm.ai/projects/ascend
```

**Method 2: Cursor Settings**

In Cursor Settings > AI Rules:

```
Context: You have access to Ascend NPU skills at /path/to/awesome-ascend-skills/

Instructions:
1. When user asks about Ascend NPU, load the relevant SKILL.md
2. Follow the instructions in the skill exactly
3. Reference official documentation when available
4. Use scripts/ directory for automation when appropriate
```

#### Generic / Custom AI Tools

For AI tools that support markdown instructions:

**Method 1: System Prompt Injection**

Include this in your system prompt:

```
You have access to Ascend NPU development skills located at:
/path/to/awesome-ascend-skills/

Each skill is a directory containing:
- SKILL.md: Metadata and instructions in YAML frontmatter format
- references/: Additional documentation
- scripts/: Executable helper scripts

When a user asks about Ascend NPU topics:
1. Find the relevant skill by matching keywords in SKILL.md description
2. Read the SKILL.md file
3. Follow the instructions provided
4. Use scripts/ for automation if available
```

**Method 2: Knowledge Base Import**

If your tool supports RAG/knowledge base:

```bash
# Index all SKILL.md files
find /path/to/awesome-ascend-skills -name "SKILL.md" -exec cat {} \; > ascend-knowledge-base.md

# Import to your AI tool's knowledge base
```

### How Skills Work

Once installed, skills are **automatically activated** based on:

1. **Description matching**: The `description` field in each SKILL.md contains keywords
2. **Context awareness**: Skills trigger when user queries match the description
3. **Progressive loading**: 
   - Only `name` and `description` loaded initially (~100 tokens)
   - Full `SKILL.md` loaded when triggered
   - `references/` and `scripts/` loaded on demand

### Skill Structure

Each directory with a `SKILL.md` is an independent skill:

```
ascend-basic-env/cann-install/
├── SKILL.md              # Required: metadata + instructions
├── references/           # Optional: detailed docs
└── scripts/              # Optional: executable scripts
```

### Skill Loading Order

When user mentions "install CANN":

1. **Discovery**: All skill `name` + `description` scanned
2. **Matching**: `cann-install` skill matches (description contains "CANN installation")
3. **Activation**: Full `cann-install/SKILL.md` loaded into context
4. **Execution**: Instructions in SKILL.md are followed

### Adding Skills to Your System

To add these skills to your environment:

1. **Clone or download** this repository
2. **Register skills** using one of the methods above
3. **Verify installation**: Skills should appear in available skills list
4. **Test**: Try a query like "How to install CANN on Ascend NPU"

### Troubleshooting Installation

| Issue | Solution |
|-------|----------|
| Skills not appearing | Check `SKILL.md` files are readable |
| Wrong skill triggered | Check `description` field contains relevant keywords |
| Skills not loading | Verify directory structure matches `name` field |
| Context overflow | Split large skills into sub-skills with references/ |

### Official Documentation

Always prefer official documentation when available:
- https://www.hiascend.com/document (Huawei Ascend)
- https://docs.vllm.ai/projects/ascend (VLLM Ascend)
- https://www.mindspore.cn (MindSpore)

---

## For Human Contributors

**If you are a human reading this repository:**

Welcome! This is an open knowledge base for Ascend NPU development. You can contribute by adding or improving Skills.

### What is a Skill?

A Skill is a self-contained unit of knowledge (a directory with a `SKILL.md` file) that teaches AI agents how to perform specific tasks related to Ascend NPU development.

### Repository Structure

```
awesome-ascend-skills/
├── ascend-npu/           # Root entry - navigation hub
├── ascend-basic-env/     # Environment setup skills
├── ascend-dev/           # Development skills
├── ascend-use-cases/     # Practical examples
└── ascend-utils/         # Shared utilities
```

### How to Contribute

#### 1. Adding a New Skill

Choose the appropriate location based on the category:

```bash
# Example: Adding a new quantization guide
mkdir -p ascend-dev/frameworks/inference/vllm/vllm-quantization
touch ascend-dev/frameworks/inference/vllm/vllm-quantization/SKILL.md
```

#### 2. Writing a SKILL.md

Template:

```yaml
---
name: skill-name
description: Clear description of what this skill does and when to use it. Include keywords.
---

# Skill Title

## Overview

Brief description of what this skill covers.

## Quick Navigation (for Master Skills)

| Task | Sub-Skill |
|------|-----------|
| Task 1 | [sub-skill-1/](sub-skill-1/SKILL.md) |
| Task 2 | [sub-skill-2/](sub-skill-2/SKILL.md) |

## Content (for Leaf Skills)

Detailed instructions, examples, code snippets...

## Official References

- [Link to official doc](url)
```

#### 3. Naming Conventions

- **Directory names**: Lowercase, hyphen-separated (`vllm-optimization`)
- **Skill names**: Match directory name (`name: vllm-optimization`)
- **Descriptions**: Clear, include keywords for agent matching
- **File references**: Use relative paths from SKILL.md

#### 4. Skill Types

**Master Skill** (routing only):
- Contains navigation table to sub-skills
- Minimal content
- Example: `ascend-dev/`, `inference/`, `vllm/`

**Leaf Skill** (detailed content):
- Contains detailed implementation guides
- May have references/ and scripts/ directories
- Example: `vllm-basic/`, `cann-install/`

#### 5. Directory Structure

```
skill-name/
├── SKILL.md              # Required
├── references/           # Optional: Documentation files
│   ├── guide.md
│   └── troubleshooting.md
└── scripts/              # Optional: Executable scripts
    ├── setup.sh
    └── example.py
```

#### 6. Best Practices

- **Link to official docs**: Always reference official documentation URLs
- **Version awareness**: Include version compatibility information
- **Progressive disclosure**: Master skills route, leaf skills detail
- **Independence**: Each skill should be usable independently
- **Keywords**: Include relevant keywords in description for agent matching

### Quick Start for Contributors

1. **Fork the repository**
2. **Create your skill** in the appropriate location
3. **Test the structure**: Ensure all links work
4. **Submit a PR** with description of what the skill covers

### Skill Checklist

Before submitting:

- [ ] `SKILL.md` exists with proper frontmatter
- [ ] `name` matches directory name
- [ ] `description` is clear and includes keywords
- [ ] Navigation works (for Master skills)
- [ ] Content is complete (for Leaf skills)
- [ ] References to official docs included
- [ ] Scripts are executable (if included)

---

## Repository Structure

```
awesome-ascend-skills/
├── ascend-npu/                    # Root entry point
├── ascend-basic-env/              # Environment setup
│   ├── cann-install/
│   ├── npu-commands/
│   ├── env-diagnostics/
│   └── testing/
│       ├── hccl-test/
│       ├── ascend-dmi/
│       └── docker-env/
├── ascend-dev/                    # Development
│   ├── frameworks/                # AI Frameworks
│   │   ├── inference/             # Inference engines
│   │   │   ├── vllm/
│   │   │   │   ├── vllm-basic/
│   │   │   │   ├── vllm-parallel/
│   │   │   │   └── vllm-optimization/
│   │   │   ├── mindie/
│   │   │   └── sglang/
│   │   └── training/              # Training frameworks
│   │       ├── mindspeed/
│   │       ├── mindspore/
│   │       └── verl/
│   └── operators/                 # Custom operators
│       ├── catlass/
│       ├── ascendc/
│       ├── triton/
│       └── tilelang/
├── ascend-use-cases/              # Examples
│   ├── operator-cases/
│   ├── inference-cases/
│   └── training-cases/
└── ascend-utils/                  # Utilities
```

## Contributing

See [For Human Contributors](#for-human-contributors) section above for contribution guidelines.

## License

TODO: Add license
