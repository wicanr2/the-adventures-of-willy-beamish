# CONTEXT — The Adventures of Willy Beamish 繁體中文化

Domain glossary。寫程式、命名、文件時一律用這套術語。

## Game / engine

- **Willy / Beamish** — The Adventures of Willy Beamish (Dynamix, 1992)。本中文化標的。中文標題《威利奇遇記》。
- **DGDS** — Dynamix Game Development System；資源/腳本引擎。ScummVM `dgds` engine 遊玩（game id `beamish`、`GID_WILLY`）。
- **RESOURCE.MAP / RESOURCE.001** — Willy 的封裝：`.MAP` 是索引、`.001` 是資料 archive。DGDS 的 **MAP 變體**（ROTD 用 `VOLUME.VGA`）。格式見 `tools/dgds_volume.py`。
- **Resource** — archive 內一條具名項目（如 `d10.dds`、`willy.fnt`）。
- **Chunk** — resource 內的具型別區塊：4-byte id 結尾 `:`（如 `DDS:`、`TT3:`、`FNT:`）+ size。高位 = container。部分 LZW/RLE 壓縮。
- **SDS** — scene script（`s<NN>.sds`）。版本 `" 1.224"`。持有 hotspot/ops/trigger，**但 1.224 不內嵌對話**。_Avoid_：以為對話在 SDS（那是 ROTD 1.211 的事）。
- **DDS** — Dialog Data Set（`d<N>.dds`）。**對話文字真正所在**。由 scene op 載入，`Dialog._str` 即字幕。鍵 `<DDS檔號>:<num>`。
- **CDS / TDS** — talkie 會話頭像動畫 + 語音（`F<n>B<n>.CDS`）/ talk-head 資料。**不含可譯文字**。_Avoid_：嘗試翻譯 CDS。
- **TTM / ADS** — 動畫/序列腳本。`TT3:` chunk 內的 SET STRING 才是畫面可見文字（告示、電腦螢幕）；`TAG:` 是內部 frame 標籤，不譯。
- **REQ** — UI request（選單/物品欄/對話框）版面 + 按鈕文字（`winv.req`、`wvcr.req`）。

## Localization

- **Dialog slot** — 單一可譯單位，鍵 `(ddsFileNum, num)`。原文一個 `_str`，行以 `\r` 分隔。
- **Base game** — 英文 CD 版（`game/`）。翻譯 `dialogs_en.json` → 注入。
- **Source encoding** — DOS **CP437**。
- **zh.dtr** — DTRN 翻譯包（Big5）。`tools/build_translation.py` 產。改翻譯只要重建這個。
- **beamish_zh{16,24}.dcjk** — 點陣 CJK 字型（Big5 linear index）。`tools/build_cjk_font.py` 產。
- **Game font** — Willy 用 `willy.fnt` / `comix_16.fnt` / `wvcr.fnt`（外加 `4x5/6x6/8x8`）。
- **DisplayMode** — F8 循環：英文原版 / 中文 24×24 / 中文 16×16。

## 譯名表（character / proper-noun glossary）

> 翻譯一律用，確保全劇本一致。`✓`=定案，`?`=草稿待確認。
> **方針（使用者定）：忠實主角「威利」＋配角玩梗。**
> 名字旁數字＝該角色在 2105 句 DDS 對話中的台詞數（出場份量）。

### 主角家庭（Beamish 一家）— 忠實直譯

| 英文 | 中文 | 備註 |
|---|---|---|
| Willy Beamish ✓ | **威利** | 308句。9 歲主角。姓 Beamish→比米許（語境可省）|
| Gordon ✓ | **戈登** | 105句。父，水管工，被工會老大陷害失業。名牌「戈登」/「比米許先生」|
| Sheila ✓ | **希拉** | 89句。母。名牌「希拉」/「比米許太太」。原文亦有誤拼 SHIELA |
| Tiffany ✓ | **蒂芬妮** | 69句。青少女姊姊，黏電話、戀愛腦 |
| Brianna ✓ | **布莉安娜** | 29句。嬰兒妹妹 |
| Ghost Beamish ✓ | **比米許爺爺**（鬼魂）| 21句。過世爺爺化作鬼魂給威利建議 |
| Duffy / Dufus ✓ | **杜菲** | 家裡的狗（過場「Willy walks Duffy」）|
| **Horny** ✓ | **霍尼** | ⭐ **威利的寵物青蛙**（40 句），訓練去比 Tootsweet 青蛙跳大賽。**不是 Sparky**（遊戲無 Sparky）、也不是 Nintari 惡魔 |
| Gigi ✓ | **姬姬** | 母青蛙，霍尼的愛慕對象 |
| Turbofrog ✓ | **渦輪蛙** | 對手參賽蛙（紀錄保持者）|

### 配角 — 適度玩梗

| 英文 | 中文 | 備註 |
|---|---|---|
| Leona Humphries ? | **莉歐娜** | 62句。反派惡保姆。玩梗候選：李歐娜「主任」|
| Dana ? | **黛娜** | 53句。待確認身分（疑 Tiffany 友/鄰居）|
| Perry ? | **派瑞** | 41句。威利的好友 |
| Spider ? | **蜘蛛** | 29句。幫派成員（Willy 同夥）|
| Coach Beltz ? | **貝爾茲教練** | 29句 |
| Frick ? | **弗里克教官** | 25句。學校訓導（Mr. Frick）|
| Louis Stoole ? | **路易·史圖爾** | 22句。貪腐水管工會老大（Big Louie）。玩梗候選：大佬路易 |
| Ms. Glass ? | **葛拉斯老師** | 21句。班導 |
| Stan Lather ? | **史丹·拉瑟** | 13句 |
| Arthur / Ray / Alicia / Frank / Burt / Gus / Hans … | 音譯待定 | 其餘小配角，翻譯時音譯並登錄 |

### 專有名詞 / 戲仿 — 玩梗

| 英文 | 中文 | 備註 |
|---|---|---|
| Nintari ? | **任天哩** | 任天堂戲仿掌機。玩梗 |
| Tootsweet Frog Jump Contest ? | **Tootsweet 青蛙跳大賽** | 主線比賽。Tootsweet 汽水品牌 |
| Gloomers ? | **下水道怪** | 下水道生物 |
| Sentinel / Plumbers Union ? | **水管工會** | 戈登任職、被陷害 |
| Carbuncle Elementary ? | **卡邦可小學** | 威利的學校（過場字幕）|
| KNTY / KMED / KROK / KBAT / KGOD / KTOK ? | 廣播台呼號（玩梗）| 電台/電視戲仿，可玩諧音 |

說話人標籤格式：`WILLY:` → `威利：`（全形冒號）。原文有誤拼（SHIELA→Sheila、LORY LOVCAKE→Lory Lovecakes、MR FRICK→Mr. Frick）翻譯時一併歸位。

## 1990s 官方術語 oracle

- **軟體世界第 34、35 期攻略**（作者阿寬）逐頁轉寫於 [`docs/攻略/軟體世界-威利奇遇記-完全攻略.md`](docs/攻略/軟體世界-威利奇遇記-完全攻略.md)。
- 標題《威利奇遇記》、青蛙跳賽事「凱旋大賽」等 1990s 用法可參考；但**人名/拼字一律以遊戲 `dialogs_en.json` 為準**（雜誌有 OCR 與人工翻譯誤差，如 Frumford→Frumpton、NINTAW→Nintari）。

## Flagged ambiguities

- 配角玩梗程度（Leona 反派、Nintari 戲仿、電台呼號等）待定。
- ~~Sparky 青蛙~~ 已釐清：寵物青蛙是 **Horny（霍尼）**，遊戲中無 Sparky。
