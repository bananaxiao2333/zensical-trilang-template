---
title: 起步
icon: lucide/rocket
description: 目录分层、单一手写层，以及一条命令背后跑的是哪几步。
tags: ["build"]
---

# 起步

<p class="kicker">GETTING STARTED</p>

## 两层目录

```
content/   唯一手写层。文件名带语言后缀：guide/index.zh-hans.md、guide/index.en.md
docs/      构建层。.md 全部由 tools/docsgen.py 产出
```

`docs/` 下的 `.md` 顶部都有一行「由 tools/docsgen.py 生成，请勿手改」——
这行横幅就是「哪些文件是生成物」的判据，因此不必再维护一份清单。
手写的 `docs/**/*.md` 不带横幅，不会被误删。

!!! warning "改了 content/ 一定要重新生成"
    `docs/` 是**提交进仓库**的，构建直接读它。改了 `content/` 却没跑 `make gen`，
    构建出来的仍是旧内容，而这一步不会有任何报错。
    `make build` 与 CI 都先跑生成，就是为了堵住这个缺口。

## 一条命令跑什么

```
make build = docsgen → navgen → zensical build --strict → linkcheck → chunker --check → i18n_check
```

后三步都是在**构建产物上**做体检，源的校验看不到它们：

* `linkcheck` —— 站内引用、目录尾斜杠、跳转桩目标是否都落地；
* `chunker --check` —— 大文件归档的分片与清单对不对得上（没有归档就直接跳过）；
* `i18n_check` —— 译文有没有漏、有没有过期、结构对不对得上。

标签索引不在这条链上：它由 `docsgen` 按（版本，语言）各自生成一份，
所以**预览与线上一致**（tags 插件按整个 `docs/` 扫描，没有语言概念，
用它展开出来的标签页会把三种语言的篇目混在一起）。

另有三条不在 `make build` 里的命令：

* `make serve` —— 本地预览，另起一份只把 `site_url` 换成本地根域的配置；
* `make offline` —— 出一份解压就能看的整站（去掉大文件与 404 页，地址改成 `.html` 式，
  再跑一遍 `offline_check` 确认每条站内引用都落地）；
* `make watch` —— 盯着 `content/`，改了自动重新生成（配合 `make serve` 用）。
