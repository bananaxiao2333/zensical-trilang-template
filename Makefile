# 三语文档站 · 构建流程
#
#   content/   唯一手写层：guide/index.zh-hans.md、guide/index.en.md
#   docs/      构建层：.md 由 tools/docsgen.py 生成，assets/ 等仍是手写的
#
#   make gen       从 content/ 生成 docs/，并从文件树重新生成导航
#   make check     翻译度检查：漏翻 / 过期 / 译文结构对不上，产出 agent 可读报告
#   make versions  版本清单体检：声明与 content/versions/ 是否对得上
#   make links     产物链接体检：站内引用 / 目录尾斜杠 / 跳转桩目标 / 补正脚本
#   make build     生成 → 构建站点 → 链接体检 → 翻译度检查
#   make watch     盯着 content/，改了自动重新生成 docs/（配合 make serve 用）
#   make serve     本地预览 http://127.0.0.1:8000
#   make offline   打一份解压就能看的离线站
#   make sync      为缺失的译文建立骨架，然后重新生成
#
#   make archives  归档体检：分片、哈希、页面上的按钮与清单是否两边对得上
#   make downloads 切分大文件归档并写清单（要有源文件；平时用不到）
#
# ⚠️ 这个 Makefile 里有三处**踩过才知道**的写法，改之前先读那几段注释：
#    · make 会把 `$'` 当成变量引用吃掉（正则里的 `$` 锚点连引号一起消失）；
#    · 判据要对着**那一节**看，别写 `grep -q '^enabled = true$'`（撞上别处的同名行
#      就是假绿灯，offline 那一段就是这么放过了一次）；
#    · `make build` 的 --clean 会清空 site/，serve 还开着时不要跑。

UV ?= uv

.PHONY: gen docs nav check versions archives downloads links build serve serve-subpath \
        watch sync offline offline-check clean

gen: docs nav

docs:
	$(UV) run python tools/docsgen.py

nav: docs
	$(UV) run python tools/navgen.py

check:
	$(UV) run python tools/i18n_check.py

# 版本清单体检。docsgen 生成前也会跑同一条判据（两边不过就别想生成），
# 这里单独留一个入口，好在只改 zensical.toml 时不必跑整条链。
# ⚠️ 一条版本都没声明也是合法的：那是单版本站，页眉不渲染版本切换器。
versions:
	$(UV) run python tools/versions.py

# 产物链接体检。构建会一页页重写 site/，所以它必须在 zensical 之后跑。
links: versions
	$(UV) run python tools/linkcheck.py

# 与 .github/workflows/docs.yml 用同一条命令：本地过得去就等于 CI 过得去。
build: gen
	$(UV) run zensical build --clean --strict
	$(UV) run python tools/linkcheck.py
	$(UV) run python tools/chunker.py --check
	$(UV) run python tools/i18n_check.py

# ── 预览 ──────────────────────────────────────────────────────────────────
# ⚠️ `zensical serve` 自己构建、自己服务，插不进 linkcheck 与 i18n_check 的产物部分，
#    所以**预览里没有那两项体检**——它们是构建之后才做得了的事。
#    （标签索引不在此列：它由 docsgen 按语言各自生成，预览与线上一致。）
#
# 预览为什么要另起一份配置
# ------------------------
# 线上站点往往**不在域名根**：托管方给的是
#     https://<用户名>.github.io/<仓库名>/
# 也就是站点根落在那一层，所以 zensical.toml 里的 site_url 必须带着 /<仓库名>/。
# 这是**不能按「本地预览方便」来取舍**的一项：站内绝对引用、sitemap、canonical
# 都按这个根拼，少了它，本地看着一切正常，一上线全是断链。
#
# 而 `zensical serve` 没有覆盖 site_url 的选项，于是它按配置把
# `http://127.0.0.1:8000/` 302 到 `/<仓库名>/`——本地预览不该背这个包袱。
# 办法是另生成一份 zensical.preview.toml，**只把 site_url 换成本地根域**，
# 其余配置一行不动；那份文件是生成物、不入库，也改不到线上的 site_url。
SERVE_ROOT_URL ?= http://127.0.0.1:8000/
PREVIEW_CONFIG = zensical.preview.toml

serve: gen $(PREVIEW_CONFIG)
	@echo "预览入口： $(SERVE_ROOT_URL)"
	$(UV) run zensical serve -f $(PREVIEW_CONFIG) -a 127.0.0.1:8000

# 要核对「线上那种子路径」下的表现（绝对引用、canonical、sitemap）就用这个。
# 它把 zensical.toml 里的 site_url 读出来，直接告诉你入口在哪儿。
serve-subpath: gen
	@printf '预览入口： %s  （按 zensical.toml 的 site_url，与线上一致）\n' \
	  "$$(sed -n 's|^site_url = "\(.*\)"|\1|p' zensical.toml | head -1)"
	$(UV) run zensical serve -a 127.0.0.1:8000

# 只把 site_url 换成本地根域，其余一行不动。用 sed 而不是「复制再改」，
# 是为了让「除了 site_url，两份配置完全相同」这件事一眼可见。
$(PREVIEW_CONFIG): zensical.toml
	@sed 's|^site_url = .*|site_url = "$(SERVE_ROOT_URL)"|' zensical.toml > $@
	@grep -qx 'site_url = "$(SERVE_ROOT_URL)"' $@ || { echo "预览配置没换掉 site_url，先看 zensical.toml"; rm -f $@; exit 1; }

# 预览时另开一个终端跑这个：`zensical serve` 只盯 docs/（生成物），
# 改 content/ 下的源文件它看不见——这一步把「content/ → docs/」自动接上。
# 两个一起开，改完存盘就能在浏览器里看到。
watch:
	$(UV) run python tools/watch.py

sync:
	$(UV) run python tools/i18n_check.py --sync
	$(MAKE) gen

# ── 大文件归档 ────────────────────────────────────────────────────────────
# 托管方对**单个文件**往往有上限（EdgeOne Pages 是 25 MB，比 git 的 100 MB 紧得多）。
# 超过上限的材料按固定大小切成 `<名字>.partNNN`，随站点一起发布，读者在浏览器里
# 取回分片、逐片校验、拼回整份再保存（见 docs/javascripts/downloads.js）。
#
# ⚠️ 分片是**最终形态**，不是中间产物：仓库里存的就是分片，部署时原样上传。
# ⚠️ 单文件上限写死在 tools/chunker.py 的 LIMIT 里，要调得有理由；
#    切完之后每个文件都必须**严格小于**它（边界值算不算超，各家实现不一）。
#
# 源文件放哪儿由 SOURCES 给，默认 ~/Downloads；要切哪几个由 ARCHIVES 列。
# 用不上的话这两个目标可以整段删掉：除了这里，只有 chunker --check 那一步在
# build 与 CI 里挂着（它没有归档时什么都不做，所以留着也不碍事）。
SOURCES ?= $(HOME)/Downloads
ARCHIVES ?=

archives:
	$(UV) run python tools/chunker.py --check

downloads:
	@test -n "$(ARCHIVES)" || { echo "先列要切的文件：make downloads ARCHIVES=\"a.zip b.rar\"（源在 $(SOURCES)/）"; exit 1; }
	$(UV) run python tools/chunker.py --src "$(SOURCES)" $(ARCHIVES)

# ── 离线文件版 ────────────────────────────────────────────────────────────
# `make offline` 出一份**解压就能看**的整站，给不能上网／不想开服务器的人：
#
#     offline:  生成 → 用离线配置构建 → 给跳转桩补 .html 副本 → 去掉归档 → 一个 zip
#
# 与线上版的三处不同，都在 zensical.offline.toml 里（由 zensical.toml 用 sed 生成）：
#
#   1. **site_dir 换成 site-offline/**，两版互不覆盖；
#   2. **打开 offline 插件**：它把 use_directory_urls 关掉，页面从 `guide/` 变成
#      `guide.html`。file:// 下面浏览器不会把 `guide/` 解析到 `guide/index.html`，
#      不关这一项整站的导航都点不动（实测就是浏览器的目录列表）；
#   3. **去掉 downloads/**（可选）：归档动辄几百 MB，占了整包的九成，而离线包本来
#      也下载不了——分片拼装靠页面里的 fetch，file:// 下会被跨域策略拦掉。
#      那一页留着当清单看，按钮点不动是意料之中的；没有 downloads/ 时这条 rm 空转。
#   4. **去掉 404.html**：它的站内引用是绝对路径（因为它要能在任意目录下被服务器
#      拿出来用），离线版没有服务器，它永远不会被渲染出来，留着只是一页断链。
#
# ⚠️ 它**不跑** linkcheck 与 i18n_check：那两条都假定目录式地址（`…/page/`），
#    离线版全是 `.html`，跑了只会满屏假警报。它跑的是 tools/offline_check.py——
#    同一套判据（每条站内引用都得落地）另写的一遍，外加锚点。
#
# ⚠️ 搜索在离线版里**用不了**：索引 search.json 是 fetch 来的，file:// 下会被
#    跨域策略拦掉。要用得把索引内联进页面再改主题的取数逻辑，那是另一件事。
OFFLINE_CONFIG = zensical.offline.toml
OFFLINE_DIR = site-offline
OFFLINE_ZIP ?= $(notdir $(CURDIR))-offline.zip

offline: gen $(OFFLINE_CONFIG)
	@rm -rf $(OFFLINE_DIR)
	$(UV) run zensical build -f $(OFFLINE_CONFIG) --strict
	$(UV) run python tools/offline_stubs.py $(OFFLINE_DIR)
	@rm -rf $(OFFLINE_DIR)/downloads $(OFFLINE_DIR)/404.html
	$(UV) run python tools/offline_check.py $(OFFLINE_DIR)
	@rm -f $(OFFLINE_ZIP)
	@cd $(OFFLINE_DIR) && zip -qr ../$(OFFLINE_ZIP) . && cd ..
	@printf '离线包：%s\n' "$(OFFLINE_ZIP)"
	@du -sh $(OFFLINE_DIR) $(OFFLINE_ZIP)

# 只体检现有的 site-offline/，不重打（改完一点东西想先看一眼时用）。
offline-check:
	$(UV) run python tools/offline_check.py $(OFFLINE_DIR)

# 与预览配置同一套办法：sed，只改该改的两行，其余一行不动。
# 第二行的行尾注释（`# 离线`）是**锚点**，免得 sed 撞上别处恰好也是
# `enabled = false` 的行——那一行连着 zensical.toml 里的说明一起改，别删。
#
# ⚠️ 判据用 awk 对着**那一节**看，不写 `grep -q '^enabled = true$'`：
#      · make 会把 `$'` 当成「名为 ' 的变量」吃掉，正则尾巴那个 $ 连带着收尾的引号
#        一起消失，于是 shell 收到一个不闭合的引号——报错还指不到这里；
#      · 更要紧的是**假绿灯**：search 与 tags 那两节本来就写着 `enabled = true`，
#        拿它当判据的话，offline 那一节压根没改成也会一路放行（踩过一次，
#        结果是整包生成了目录式地址，file:// 下点导航变成浏览器的目录列表）。
$(OFFLINE_CONFIG): zensical.toml
	@sed -e 's|^site_dir = .*|site_dir = "$(OFFLINE_DIR)"|' \
	     -e 's|^enabled = false.*离线|enabled = true|' zensical.toml > $@
	@grep -qx 'site_dir = "$(OFFLINE_DIR)"' $@ || { echo "离线配置没换掉 site_dir"; rm -f $@; exit 1; }
	@awk '/^\[project\.plugins\.offline\]/{getline; if ($$0 == "enabled = true") ok = 1} \
	      END{exit !ok}' $@ || { echo "离线配置没打开 offline 插件（那一行的行尾锚点注释还在吗）"; rm -f $@; exit 1; }

clean:
	rm -rf site $(OFFLINE_DIR) $(OFFLINE_ZIP) $(PREVIEW_CONFIG) $(OFFLINE_CONFIG)
