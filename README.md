# さなくり 無音印刷（デジカル会計・デジスマ予約票）

デジカルの会計画面・デジスマ診療の予約票を、PDFタブを開かずに OKI から A5 で無音印刷するための一式です。
各PCには **Tampermonkey のスクリプト 2本** と **常駐の印刷係（watcher）** が入ります。どちらもこのリポジトリから自動更新されます。

| ファイル | 役割 |
|---|---|
| [`sanakuri_kaikei.user.js`](sanakuri_kaikei.user.js) | デジカル会計画面：「🖨 保存して印刷 (F9)」「保存のみ」ボタン（Tampermonkey） |
| [`sanakuri_digisma.user.js`](sanakuri_digisma.user.js) | デジスマ：「🖨 予約して印刷」、チェックイン履歴の各行 🖨、「🖨 予約票を無音印刷」（Tampermonkey） |
| [`watcher/`](watcher/) | 常駐の印刷係（`C:\sanakuri` の中身）。`VERSION.txt` と `manifest.txt` で自動更新 |

## 新しいPCへの導入（約10分）

1. **常駐（watcher）** — スタートメニューで「PowerShell」を検索 → 右クリック →「管理者として実行」→ 次の1行を貼り付けて Enter
   ```
   [Net.ServicePointManager]::SecurityProtocol='Tls12'; iwr -useb https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/watcher/install.ps1 | iex
   ```
   （`C:\sanakuri` に一式と SumatraPDF が入り、Chrome 設定・自動起動の登録・常駐起動まで自動。[`watcher/install.bat`](watcher/install.bat) を保存してダブルクリックでも可）
2. `C:\sanakuri\test_print_kpdf.bat` をダブルクリック → OKI から A5 のテスト紙が出れば OK
3. **Tampermonkey** — Chrome ウェブストアで Tampermonkey を追加 → `chrome://extensions` → Tampermonkey の「詳細」→「ユーザースクリプトを許可する」をオン
4. 次の2つを順に開いて「インストール」
   - `https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_kaikei.user.js`
   - `https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_digisma.user.js`
5. Chrome を開き直し、デジカル・デジスマで F5 → 会計画面に青いボタンが出れば完了

詳しい手順・困ったときは [`watcher/README.txt`](watcher/README.txt)。

### PowerShell が制限されている PC（受付PC）
受付PCは一般権限では PowerShell が禁止（業者の初期設定）ですが「管理者として実行」なら動きます。setup は管理者で実行されると常駐を **タスク スケジューラ（ログオン時・最上位の特権）** に登録するので、禁止設定を変えずに動きます。制限のない PC（診察室PC）では従来どおりスタートアップ登録です。`.bat` 類は PowerShell を使わない作りにしてあります。

## 自動更新のしくみ

- **Tampermonkey スクリプト**：ヘッダの `@updateURL` / `@downloadURL` がこのリポジトリを指しています。`@version` を上げて push すると、各PCの Tampermonkey が（既定で1日1回）取り込みます。手動なら Tampermonkey アイコン →「ユーザースクリプトの更新を確認」。
- **watcher**：起動時と6時間ごとに `watcher/VERSION.txt` を確認し、新しければ `watcher/manifest.txt` のファイルを取得して置き換え、自分で再起動します。各PCの `config.txt`（プリンター名など）と `SumatraPDF.exe` は触りません。`check_update.bat`（今すぐ確認）／`restart_watcher.bat`（再起動）は `update.flag`／`restart.flag` を置くだけの作りです。
- 更新を出すときは：変更 → `watcher/VERSION.txt` を上げる（スクリプトは `@version` も）→ `main` に push。それだけです。

## 安全側の設計

- スクリプトはデジカル／デジスマのデータを一切変えず、本来の「保存」「予約」ボタンを押しているだけです。画面の作りが変わっても「追加ボタンが出ない／従来どおりPDFタブが開く」に戻るだけ。Tampermonkey でスクリプトを OFF にすれば完全に元の動作です。
- watcher はダウンロードフォルダの `sanakuri_*.kpdf` だけを拾って印刷し、`printed\` に移します。失敗分は `failed\`、記録は `log.txt`。
- 更新を止めたい PC は `config.txt` の `UPDATE_SOURCE=off`。
