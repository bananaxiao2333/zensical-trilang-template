---
title: 命令与体检
icon: lucide/terminal
description: make 目标一览，以及三条构建后体检各自守什么。
tags: ["build"]
---

# 命令与体检

<p class="kicker">COMMANDS & CHECKS</p>

```bash
make gen       # content/ → docs/，并重新生成导航
make check     # 只跑翻译度体检
make links     # 只跑产物链接体检（需先构建）
make build     # 生成 → 构建 → 链接体检 → 归档体检 → 翻译度体检
make serve     # 本地预览（另起一份只换 site_url 的配置）
make watch     # 盯着 content/，改了自动重新生成
make offline   # 打一份解压就能看的离线整站
make sync      # 为缺失的译文建立骨架，然后重新生成
make clean     # 删掉 site/ 与离线产物
```

## 三条体检各自守什么

| 脚本 | 守的是 | 为什么源的校验看不到 |
| --- | --- | --- |
| `tools/linkcheck.py` | 站内引用、目录尾斜杠、跳转桩目标、地址补正脚本 | 这些都是构建后才定型的链接 |
| `tools/i18n_check.py` | 漏翻 / 过期 / 结构对不上 / 产物缺件 | 需要同时看内容与产物 |
| `tools/chunker.py --check` | 归档分片与清单、页面按钮与清单两边对账 | 分片是仓库里的成品，只有构建体系自己知道谁引用了它 |
| `tools/offline_check.py` | 离线包里每条引用与锚点 | 离线版是另一种地址形状，线上那套判据量不了它 |

标签索引不在这张表里：它由 `tools/docsgen.py` 按（版本，语言）生成一份，
不走「构建后事后过滤」那条路——预览因此与线上一致。

`i18n_check.py` 还会对构建产物做一组「该有的东西真的在」的断言（SMOKE）：
模板里的条件一旦恒为假，输出会**静默**少一块——不报错、不警告。
