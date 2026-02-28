## CANN DataType / Format 参考

- **DataType 枚举（`ge::DataType`）**
  - 定义位置：`graph/types.h` 中的 `enum DataType`，典型路径：
    - `/usr/local/Ascend/cann-8.5.0-beta.1/aarch64-linux/include/graph/types.h`（约 80–123 行）
  - 常用取值示例：
    - `ge::DT_FLOAT`
    - `ge::DT_FLOAT16`
    - `ge::DT_BF16`
    - `ge::DT_INT8`
    - `ge::DT_INT32`
    - `ge::DT_BOOL`

- **Format 枚举（`ge::Format`）**
  - 定义位置：同一文件 `graph/types.h` 中的 `enum Format`，典型路径：
    - `/usr/local/Ascend/cann-8.5.0-beta.1/aarch64-linux/include/graph/types.h`（约 189–247 行）
  - 常用取值示例：
    - `ge::FORMAT_ND`
    - `ge::FORMAT_NCHW`
    - `ge::FORMAT_NHWC`
    - `ge::FORMAT_FRACTAL_NZ`

- **JSON → C++ 映射约定（示例）**
  - `type: "fp16"` → `ge::DT_FLOAT16`
  - `type: "bf16"` → `ge::DT_BF16`
  - `type: "float"` → `ge::DT_FLOAT`
  - `type: "int32"` → `ge::DT_INT32`
  - `format: "ND"` → `ge::FORMAT_ND`

### 每个输入/输出的 DataType、Format、UnknownShapeFormat 元素个数必须一致

在 `*_def.cpp` 中，对每个 `Input("xxx")` / `Output("yyy")`：

- **`.DataType({ ... })`**、**`.Format({ ... })`**、**`.UnknownShapeFormat({ ... })`** 三个列表的**元素个数必须相同**。
- 即：若支持 3 种数据类型，则 DataType、Format、UnknownShapeFormat 均应为 3 个元素；若只支持 1 种，则三个均为 1 个元素。
- 否则会导致框架解析异常或 op_build 校验失败。

示例（3 种类型一致）：

```cpp
this->Input("expanded_x")
    .ParamType(REQUIRED)
    .DataType({ge::DT_FLOAT16, ge::DT_BF16, ge::DT_FLOAT})   // 3 个
    .Format({ge::FORMAT_ND, ge::FORMAT_ND, ge::FORMAT_ND})   // 3 个
    .UnknownShapeFormat({ge::FORMAT_ND, ge::FORMAT_ND, ge::FORMAT_ND})  // 3 个
    .AutoContiguous();
```

示例（单一类型一致）：

```cpp
this->Input("expanded_row_idx")
    .ParamType(REQUIRED)
    .DataType({ge::DT_INT32})
    .Format({ge::FORMAT_ND})
    .UnknownShapeFormat({ge::FORMAT_ND})
    .AutoContiguous();
```

---

> 约定：所有新算子的 `op_host` `.DataType()` / `.Format()`，以及 tiling 中的 dtype 校验，都应只使用 `graph/types.h` 中已经定义的枚举值，并与算子 JSON 中的 `type` / `format` 保持一致；且每个输入/输出的 DataType、Format、UnknownShapeFormat 元素个数保持一致（见上文）。

