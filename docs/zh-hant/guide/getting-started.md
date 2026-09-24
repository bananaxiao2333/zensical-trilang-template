---
title: 起步
icon: lucide/rocket
description: 目錄分層、單一手寫層，以及一條命令背後跑的是哪幾步。
tags: ["build"]
# ⚠️ 由 tools/docsgen.py 從 content/guide/getting-started.zh-hans.md 生成，請勿手改；要改請改 content/ 下的源文件。 （本頁由 zh-hans 版腳本轉換而來，不是另譯）
---

# 起步

<p class="kicker">GETTING STARTED</p>

## 兩層目錄

```
content/   唯一手寫層。文件名帶語言後綴：guide/index.zh-hans.md、guide/index.en.md
docs/      構建層。.md 全部由 tools/docsgen.py 產出
```

`docs/` 下的 `.md` 頂部都有一行「由 tools/docsgen.py 生成，請勿手改」——
這行橫幅就是「哪些文件是生成物」的判據，因此不必再維護一份清單。
手寫的 `docs/**/*.md` 不帶橫幅，不會被誤刪。

!!! warning "改了 content/ 一定要重新生成"
    `docs/` 是**提交進倉庫**的，構建直接讀它。改了 `content/` 卻沒跑 `make gen`，
    構建出來的仍是舊內容，而這一步不會有任何報錯。
    `make build` 與 CI 都先跑生成，就是為了堵住這個缺口。

## 一條命令跑什麼

```
make build = docsgen → navgen → zensical build --strict → linkcheck → chunker --check → i18n_check
```

後三步都是在**構建產物上**做體檢，源的校驗看不到它們：

* `linkcheck` —— 站內引用、目錄尾斜槓、跳轉樁目標是否都落地；
* `chunker --check` —— 大文件歸檔的分片與清單對不對得上（沒有歸檔就直接跳過）；
* `i18n_check` —— 譯文有沒有漏、有沒有過期、結構對不對得上。

標簽索引不在這條鏈上：它由 `docsgen` 按（版本，語言）各自生成一份，
所以**預覽與線上一致**（tags 插件按整個 `docs/` 掃描，沒有語言概念，
用它展開出來的標簽頁會把三種語言的篇目混在一起）。

另有三條不在 `make build` 裡的命令：

* `make serve` —— 本地預覽，另起一份只把 `site_url` 換成本地根域的配置；
* `make offline` —— 出一份解壓就能看的整站（去掉大文件與 404 頁，地址改成 `.html` 式，
  再跑一遍 `offline_check` 確認每條站內引用都落地）；
* `make watch` —— 盯着 `content/`，改了自動重新生成（配合 `make serve` 用）。
