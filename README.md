# Zensical 三语文档站模版

> 一个开箱即用的**三语静态文档站**骨架：简体中文手写、英文手写并带指纹、
> 繁体由脚本从简体转换而来。**`content/` 是唯一手写层**，`docs/` 下的每一篇
> 都是生成的。
>
> 它主要解决一件事：**译文会悄悄过期**。默认语言改了，译文还是旧的，构建一路绿灯。
> 这里把「译文过没过期」变成一次会以非零码退出的检查。
>
> 另有三件现成的能力，都按需打开：**第二条网址轴（版本）**、**大文件分片下载**、
> **解压即看的离线包**。

---

## 快速开始

```bash
# 需要 Python ≥ 3.14 与 uv
uv sync --locked

make gen      # content/ → docs/，并重新生成导航
make serve    # 预览 http://127.0.0.1:8000

make build    # 生成 → 构建 → 链接体检 → 归档体检 → 翻译度体检
```

`make build` 的产物是**一个纯静态目录** `site/`，交给任何静态托管即可。

三份文档的分工：[`README.md`](README.md)（本文，怎么用）、
[`TRANSLATION-GUIDE.md`](TRANSLATION-GUIDE.md)（译文怎么写、怎么验收）、
[`LESSONS.md`](LESSONS.md)（**为什么非得写成现在这样**：哪些改法会静默出错、
判据立在哪里才拦得住）。要动模板或 Makefile 之前，先读第三份。

---

## 它长什么样

```
content/     唯一手写层。文件名带语言后缀
  index.zh-hans.md      ┐
  index.en.md           ┴─ 同一篇的两个语种
  guide/
    index.zh-hans.md    ← 这个目录的导航元数据也写在这里
    getting-started.zh-hans.md
  versions/<id>/        ← 非当前版的冻结快照（开了版本轴才有）

docs/        构建层。.md 与 .nav.yml 都是生成物
  index.md              ← 默认语言，网址不带前缀
  en/index.md
  zh-hant/index.md
  v1/…                  ← 版本轴打开之后：版本在前、语言在后
  assets/               ← 共享资产，三棵树共用一份
  stylesheets/          ← 手写
  javascripts/          ← 手写
  downloads/            ← 大文件归档本体与清单（手写/生成各半，见「大文件归档」）

tools/       生成器与体检（纯标准库 + pyyaml + zhconv）
overrides/   主题模板覆盖
site/        构建产物（不入库）
```

## 三种语言，两种来源

| | 来源 | 判据 | 手改哪里 |
| --- | --- | --- | --- |
| 简体 `zh-hans` | 手写 | —— | `content/**/*.zh-hans.md` |
| 英文 `en` | 手写译文 | 译文里记的 `source_sha256` 与原文对得上 | `content/**/*.en.md` |
| 繁体 `zh-hant` | 由简体**脚本转换** | 转换结果与产物**逐字节**一致 | 不要手改，改简体 |

派生语言不是「第二种翻译」，是同一份文字的字符转写，所以它**不可能过期**。
哪些字不转（反引号里的文件名、链接目标）、哪些古体异写要归一，
见 [`tools/hant.py`](tools/hant.py) 开头的说明。

## 加一种语言

语言清单**从 `content/` 的文件名后缀推导**（见 [`tools/langs.py`](tools/langs.py)），
没有一份需要手工维护的语言列表。所以加一种语言分两步：

1. 在 `content/` 里给它写**至少一篇**——一门语言的存在与否由文件说了算；
2. `uv run python tools/i18n_check.py --sync` 会把其余缺失篇目的骨架补齐。

> **删掉某语言的全部内容，那门语言就消失了。** 这是推导式设计的代价，
> 也是它的好处：不存在「配置里写着 en，但一篇英文也没有」这种半死状态。

再加一门**派生**语言（脚本转换，如简体 → 繁体），改 `tools/langs.py` 的
`DERIVATIONS` 与转换函数即可；其余脚本都会跟着走。

---

## 会挡住你的体检

除最后一条外，全部跑在**构建产物**上——源的校验看不到它们。

| 脚本 | 守什么 | 为什么必须在构建之后 |
| --- | --- | --- |
| [`tools/linkcheck.py`](tools/linkcheck.py) | 站内引用落地、目录引用带尾斜杠、跳转桩目标存在、每页都带目录地址补正脚本 | 这些都是构建后才定型的链接 |
| [`tools/i18n_check.py`](tools/i18n_check.py) | 漏翻 / 过期 / 结构对不上 / 产物缺件（SMOKE 断言） | 要同时看内容与产物 |
| [`tools/chunker.py`](tools/chunker.py) `--check` | 归档分片与清单对得上、页面上的按钮与清单两边对账 | 分片是仓库里的成品，只有构建体系知道谁引用了它 |
| [`tools/offline_check.py`](tools/offline_check.py) | 离线包里每条引用与锚点都落地 | 离线版是另一种地址形状（`.html` 式），线上那套判据量不了它 |
| `zensical build --strict` | 断链、失效锚点 | 源级校验 |

标签索引不在这张表里：它由 `docsgen.py` 按（版本，语言）生成一份，
不走「构建后过滤产物」那条路——所以**预览与线上一致**。

`i18n_check` 的**结构比对**值得单独说：它不数字符，而是比标题层级序列、
表格行数、提示框数、卡片数、代码块数、图片数与链接集合。漏掉一整段、
少一行表格、把提示框写成普通段落，都拦得住——这些光看「翻译进度 100%」是看不见的。

```bash
make check    # 只跑翻译度体检
make links    # 只跑链接体检（需先构建）
make archives # 只跑归档体检（没有归档时直接跳过）
```

---

## 可选的第二条轴：版本

网址有两个**正交**的维度，**版本在前、语言在后**：

```
/                     当前版 · 默认语言        /v1/                   v1 版 · 默认语言
/en/                  当前版 · 英文            /v1/en/                v1 版 · 英文
```

「版本在前」是为了让绝大多数人进来的那一支（当前版的默认语言）停在最浅的地址上。
两条轴的判据只有一份，在 [`overrides/partials/route.html`](overrides/partials/route.html)；
页眉上两个切换器**各改一层前缀**，互不越权（版本见 `partials/version.html`，
语言见 `partials/alternate.html`）。

**这条轴默认是关着的**：`zensical.toml` 里一条 `[[project.extra.version]]` 都不写，
站点就是单版本站，页眉不渲染版本切换器，其余一切照常。要开就声明两条以上：

```toml
[[project.extra.version]]
id = "v1"                 # 就是网址那一段；只能是 URL 里不用转义的字符
label = "1.0 版"          # 切换器上显示的名字
date = "2027-01-15"
current = true            # 当前版**没有**网址前缀，它的内容在 content/ 根下

[[project.extra.version]]
id = "v0"
label = "0.9 版"
```

当前版的内容就在 `content/` 根下；其余各版是**冻结的快照**，
整棵放在 `content/versions/<id>/` 下，之后不再回改。旧版缺的页
由 `docsgen.py` 补一个跳转桩（`<meta http-equiv="refresh">`），
把人送到那一版的首页，而不是送进 404。

> ⚠️ 冻进去的那棵树要**自洽**：它自己的 `index.md` 里 `nav:` 只列它真有的分区，
> 正文里的相对链接也只指向它真有的页。跳转桩补的是**产物地址**（浏览器那一侧：
> 切换器、跨树导航），补不了树内部的 markdown 链接——指着本树没有的页，
> `zensical build --strict` 会直接报 `page does not exist`。
> 要么整棵复制，要么把它裁剪成自洽的一片。

> 声明与内容必须两边对得上：声明了没目录、有目录没声明、id 重复、
> 当前版不是恰好一个，`make versions` 都以非零码退出。
> 唯独「一条都没声明」是合法的——那是单版本站。

---

## 离线文件版

```bash
make offline      # 出一份 <仓库目录名>-offline.zip，解压双击 index.html 就能看
```

它与线上版的四处不同，都在 `zensical.offline.toml` 里（由 `zensical.toml` 用 sed 生成，
只改该改的两行）：

1. `site_dir` 换成 `site-offline/`，两版互不覆盖；
2. 打开 Zensical 自带的 `offline` 插件——它把 `use_directory_urls` 关掉，页址从
   `guide/` 变成 `guide.html`。**这一条是必需的**：`file://` 下浏览器不会把
   `guide/` 解析到 `guide/index.html`，目录式地址整站都点不动；
3. 去掉 `downloads/`（若有大文件归档）与 `404.html`——后者站内引用是绝对路径，
   离线版没有服务器，它永远不会被渲染出来；
4. 构建完补一步 `tools/offline_stubs.py`：跳转桩要**补**一份 `.html` 式副本
   （不能只改名——两种链法在产物里同时存在），再跑 `tools/offline_check.py`
   验每条引用与锚点。

> 离线版里**搜索用不了**：索引 `search.json` 是 fetch 来的，`file://` 下会被跨域
> 策略拦掉。要用得把索引内联进页面再改主题的取数逻辑，那是另一件事。

---

## 大文件归档

托管方对单个文件往往有上限（比 git 紧得多）。超过上限的材料用
[`tools/chunker.py`](tools/chunker.py) 切成 `<名字>.partNNN`，随站点一起发布：

```bash
make downloads ARCHIVES="report.zip dataset.7z"   # 源文件默认在 ~/Downloads
make archives                                     # 只体检，不需要源文件（CI 跑这个）
```

页面上挂一个按钮（`<button data-dl="report">`），
[`docs/javascripts/downloads.js`](docs/javascripts/downloads.js) 把分片取回来、
逐片校验、拼回**与原文件同名**的整份再保存。几条边界值得先知道：

* **分片是最终形态**，不是中间产物——仓库里存的就是分片，部署时原样上传；
* 没超上限的文件**原样存一份**，那个按钮是一条**直链**：浏览器能下，
  下载器（IDM / aria2 / 迅雷）也能下。分片那一档只能由页面拼——拼接走的是
  `blob:` 地址，那是页面内存里的临时句柄，**下载器按不动**；
* 大小不写在页面上，从 `docs/downloads/manifest.json` 里读——两份记录会分叉；
* 单文件上限写在 `chunker.py` 的 `LIMIT` 里（默认 25 MB，可以先 `--limit` 覆盖）。

用不上就把 `Makefile` 里那两个目标删掉：`chunker --check` 在没有归档时什么都不做，
留着也不碍事。

---

## 预览

```bash
make serve          # http://127.0.0.1:8000/（另开一个终端跑 make watch，改完即见）
make serve-subpath  # 按 zensical.toml 的 site_url 预览，核对子路径部署下的绝对引用
```

站点常常**不在域名根**（托管方给的是 `https://<用户>.github.io/<仓库>/`），
所以 `site_url` 必须带着那一层——这是不能按「本地预览方便」来取舍的一项：
站内绝对引用、sitemap、canonical 都按这个根拼，少了它，本地看着一切正常，
一上线全是断链。而 `zensical serve` 没有覆盖 `site_url` 的选项，于是 `make serve`
另生成一份 `zensical.preview.toml`，**只把 `site_url` 换成本地根域**，其余一行不动。

> ⚠️ `make build` 的 `--clean` 会清空 `site/`，`make serve` 还开着时不要跑它。
> `make watch` 补的是另一段：`zensical serve` 只盯 `docs/`（生成物），
> 改 `content/` 下的源文件它看不见。

---

## 前置元数据

写在 `content/**/*.md` 顶部。完整字段表见站点里的「参考 → 前置元数据」一页，
这里只列容易踩的几条：

* **`nav` 只写在 `index.md` 里** —— 它定义的是「本目录子项的顺序」。
  一个文件夹的全部导航元数据，就写在它自己的 `index.md` 里，
  不需要另维护一份导航配置。
* **`tags` 用语言中立的标识符**（日期、代号）。各语言各写一套标签，
  横向的线索一换语言就断。
* **译文的 `source_sha256` 是必填的**。它由 `--sync` 自动写入；
  手抄一份译文时得自己算：`shasum -a 256 content/<路径>.zh-hans.md`。

---

## 多语言文案放在哪里

Zensical 里 `site_name` / `copyright` / `site_description` 这类配置是**全站唯一**的，
而本站三种语言共用一次构建。所以其余语言的值放在 `zensical.toml` 的
`[project.extra]` 里，**键名加后缀**取用（默认语言留空）：

```toml
site_name         = "文档站模版"
site_name_en      = "Docs Template"
site_name_zh_hant = "文檔站模版"
```

模板里统一这么取：

```jinja
{% set site_name = config.extra["site_name" ~ L] | d(config.site_name, true) %}
```

`L` 由页面语言决定（默认语言 `""`、英文 `"_en"`、繁体 `"_zh_hant"`），
见 [`overrides/main.html`](overrides/main.html) 开头那三行。

> 后缀用**下划线**而不是连字符，因为语言代码里本来就有连字符
> （`zh-hant` → `_zh_hant`）。

---

## 本模板的几条硬规矩

这几条都有代价，是踩过之后才立的：

**1. `docs/` 提交进仓库，但它是生成物。**
构建直接读 `docs/`，所以改了 `content/` 却忘了 `make gen`，发出去的就是旧内容——
而且**不会有任何报错**。`make build` 与 CI 都先跑生成，就是为了堵这个缺口。

判据是文件里那行生成横幅（「由 tools/docsgen.py 生成，请勿手改」），
不另存一份清单：两份记录会分叉，一份不会。手写的 `docs/**/*.md` 不带横幅，
因此不会被误认领、也不会被 prune 删掉。

**2. 链接与路径的两种写法。**
指向**站内页面**用相对路径（各语言目录结构镜像，三语通用）；
指向**共享资产**也写相对路径，`docsgen.py` 会给非默认语言的产物多补一层 `../`。
后者容易忘，所以 `linkcheck.py` 会逐页解析每一条 `href`/`src` 验它落地。

**3. 目录地址的尾斜杠。**
「少一个斜杠」的目录地址会让页面内的相对链接全部解析错位。
站点自己只生成带斜杠的地址，同时每一页都挂一小段脚本把地址栏补正
（理由与取舍见 [`overrides/partials/trailing-slash.html`](overrides/partials/trailing-slash.html)）。
`linkcheck.py` 两条都守着。

**4. 不引任何第三方请求。**
字体、样式、脚本全部自托管，`zensical.toml` 里 `theme.font = false`，
图片灯箱用的是站内副本。同意表单因此**一个勾选项都没有**——
把不存在的东西列进同意表单，才是真正的不诚实。
代价是：灯箱与字体文件要跟着主题升级手动同步，见 `zensical.toml` 里的注释。

---

## 换成你自己的内容

1. 删掉 `content/` 下全部示例，写你自己的默认语言版本；
2. `zensical.toml` 里改 `site_url` / `site_name` / `site_description` /
   `site_author` / `copyright`，以及 `[project.extra]` 的多语言值；
3. 把 `docs/assets/` 换成你自己的图；需要的话在 `[project.theme]` 里
   打开 `logo` 与 `favicon`；
4. `tools/i18n_check.py` 里的 `SMOKE` 断言表指向**示例内容**，
   换内容时同步改（它检查的是「这几页上该有的东西真的在」）；
5. `make build` 跑绿。

用不上的能力可以整段删掉，删的时候连注释一起删，别留半截：

| 不要什么 | 删哪里 |
| --- | --- |
| 版本轴 | `zensical.toml` 里不写 `[[project.extra.version]]` 即可（代码与判据会自动退化） |
| 大文件归档 | `Makefile` 的 `archives` / `downloads` 两个目标、`docs/javascripts/downloads.js`、`extra_javascript` 里那一行；`chunker --check` 留着也不碍事（没归档就跳过） |
| 遮挡块 | `docs/javascripts/redact.js` + `extra_javascript` 里那一行 + `extra.css` 里那一段 |
| 离线包 | `Makefile` 的 `offline` / `offline-check` 两段与 `[project.plugins.offline]` 那一节 |
| 派生语言 | `tools/langs.py` 的 `DERIVATIONS` 里去掉那一条（其余脚本会跟着走） |

`TRANSLATION-GUIDE.md` 是译文的写作与验收规范，里面标了几处 `⚠️` 要你替换的示例；
`LESSONS.md` 是踩坑记录，改判据之前值得先查一眼。

---

## 部署

`make build` 产出的 `site/` 是纯静态目录，与托管商无关。两种常见接法：

**A. 由托管商构建** —— 让它盯 `main`，构建命令填 `make gen && make build`，
输出目录填 `site`。前提是那台构建机能装 Python 与 uv（很多只预装 Node）。

**B. 在 CI 里构建，产物推一个分支** —— 构建环境你说了算，托管商只管搬运。
本模板带了这样一个工作流：

```
main ──push──► .github/workflows/deploy.yml
                 ├─ gen → zensical build → linkcheck → chunker --check → i18n_check
                 └─ 把 site/ 的成品 force-push 到 deploy 分支（永远只有一个提交）
                                    │
                                    ▼
                托管商盯 deploy 分支，编译命令与安装命令都留空
```

`.github/workflows/docs.yml` 只做校验、**不发布**，挂在 push 与 PR 上。

> 产物推分支时每次都用**一个全新的孤儿提交**再 `-f` 强推，而不是往旧分支上追加：
> 追加的话，上一版才有的文件会永远留在线上。

---

## 目录约定速查

```
content/          唯一手写层（非当前版在 content/versions/<id>/）
docs/             构建层（生成）+ 手写资产
  assets/         共享资产，三棵树共用
  stylesheets/    手写
  javascripts/    手写
  downloads/      归档分片与清单（要入库；见「大文件归档」）
tools/            langs.py 是语言清单的唯一出处，versions.py 读 zensical.toml
overrides/        主题模板覆盖（见下）
site/             构建产物，不入库
site-offline/     离线包与它的 zip，不入库（make offline 一条命令再生）
```

`overrides/` 里每个文件开头都写明了**它与主题原版的差异**，
以及主题升级时需要同步什么。改这些文件之前先读那段注释。
