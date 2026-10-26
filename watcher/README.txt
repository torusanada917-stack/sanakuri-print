さなくり 無音印刷（デジカル会計・デジスマ予約票） v1.8（2026-10-26）
================================================================
最新の手順・ファイルは  https://github.com/torusanada917-stack/sanakuri-print

■ できること（デジカルの会計画面：ボタンが3つ）
  🖨 保存して印刷 (F9)   → 保存して、領収書・明細・処方箋をOKIからA5で無音印刷（タブは開かない）
  保存のみ               → 保存だけ（印刷もタブもなし）
  保存（デジカル本来）   → 従来どおり保存してPDFを別タブ表示 → 手動で印刷（OKI故障時はEPSONにA5を入れてこちら）

■ できること（デジスマ診療の予約票）
  予約確認画面        → 「予約票を印刷」チェックは常に外れた状態。「🖨 予約して印刷」で予約＋OKIからA5無音印刷
  チェックイン履歴    → 各行の「詳細」列に 🖨。押すとその予約の予約票を無音印刷
  当日詳細            → 「予約票印刷」の隣に「🖨 予約票を無音印刷」

■ 仕組み
  Tampermonkey のスクリプト（デジカル用・デジスマ用）がPDFを sanakuri_….kpdf という名前でダウンロードフォルダに落とし、
  常駐の watcher（タスクトレイのオレンジのアイコン）が印刷して printed フォルダへ移動します。
  会計PDF（元からA5）は PDF をプリンターへ直接送信（速い）、予約票（B5）は SumatraPDF で A5 に縮小して「OKI B432(A5)」へ。
  直接送信先は config.txt の DIRECT_IP（届かない時は自動で SumatraPDF 方式）。

■ 自動更新（手を入れるPCは0台）
  ・Tampermonkey のスクリプト：GitHub 上の新しい版を Tampermonkey が自動で取り込みます（1日1回確認。手動なら Tampermonkey アイコン→「ユーザースクリプトの更新を確認」）
  ・常駐 watcher：起動時と6時間ごとに GitHub の VERSION.txt を見に行き、新しければファイルを入れ替えて自分で再起動します（config.txt は上書きしません）
  ・更新を止めたい時は config.txt の UPDATE_SOURCE=off

■ 受付PCのように「PowerShell が禁止」のPCについて
  受付PCは一般権限では PowerShell が動かない設定（業者の初期設定）ですが、「管理者として実行」なら動きます。
  このため setup は、管理者で実行されたときは「タスク スケジューラ（ログオン時・最上位の特権）」に常駐を登録します。
  禁止設定そのものは変えません。診察室PCのような制限のないPCは、従来どおりスタートアップ登録です。

----------------------------------------------------------------
新しいPCへの導入（約10分）
----------------------------------------------------------------
1. スタートメニューで「PowerShell」を検索 → 右クリック →「管理者として実行」→「はい」
2. 青い（または黒い）窓に、次の1行を貼り付けて Enter：
   [Net.ServicePointManager]::SecurityProtocol='Tls12'; iwr -useb https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/watcher/install.ps1 | iex
   → C:\sanakuri にファイル一式と SumatraPDF が入り、Chrome設定・自動起動の登録・常駐起動まで自動
   → タスクトレイ（画面右下 ^）にオレンジのアイコンが出れば稼働中
   （代わりに https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/watcher/install.bat を保存してダブルクリックでも可）

3. C:\sanakuri\test_print_kpdf.bat をダブルクリック → OKI から A5 のテスト紙が出れば印刷側は完成
   出ない時：list_printers_file.bat → printers.txt で「OKI B432(A5)」の名前を確認 → 違えば config.txt の PRINTER= を直し、
   restart_watcher.bat をダブルクリック

4. Chrome に Tampermonkey を入れる
   (1) Chrome ウェブストアで「Tampermonkey」→「Chromeに追加」
   (2) chrome://extensions → Tampermonkey の「詳細」→「ユーザースクリプトを許可する」をオン
   (3) 次の2つのURLを順に開き、Tampermonkey の画面で「インストール」
       https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_kaikei.user.js
       https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_digisma.user.js
   (4) Chrome をいったん全部閉じて開き直す（自動ダウンロード許可の設定を読ませるため）

5. 動作確認
   デジカル：会計画面を開く → 保存ボタンの左に青い「🖨 保存して印刷 (F9)」が出ていればOK
   デジスマ：当日詳細 → チェックイン履歴 → 各行に 🖨 が出ていればOK

----------------------------------------------------------------
困ったとき
----------------------------------------------------------------
・青いボタンが出ない → 手順4(2)の「ユーザースクリプトを許可する」とスクリプトの ON を確認し、F5
・ダウンロードがブロックされる（アドレスバー右端に矢印×）→ allow_digisma_downloads.bat を実行して Chrome を再起動
・「印刷データを送りました」と出るのに紙が出ない
    → トレイにオレンジのアイコンがあるか（無ければ start_watcher.bat をダブルクリック）
    → C:\sanakuri\log.txt を見る。「印刷失敗」なら failed フォルダに入っている。プリンター名・電源・用紙を確認
・設定(config.txt)を変えたあと → restart_watcher.bat をダブルクリック（トレイの 終了→start_watcher.bat でも可）
・元に戻したい → Tampermonkey でスクリプトを OFF（これだけで従来どおり）。常駐も止めるなら uninstall.bat

■ ファイル
  watcher.ps1 / watcher.vbs     常駐本体と起動用          config.txt           このPCの設定（自動更新で上書きされない）
  update.ps1 / VERSION.txt      自動更新                  config.default.txt   設定のひな形（最新）
  install.bat / install.ps1     新しいPCへの導入          setup_auto.bat / setup.ps1   セットアップ（管理者で実行）
  elevate.vbs                   .ps1 を管理者として実行   start_watcher.bat    常駐の起動
  restart_watcher.bat           常駐の再起動              check_update.bat     今すぐ更新確認
  test_print_kpdf.bat           テスト印刷                list_printers_file.bat  プリンター一覧→printers.txt
  get_sumatra.bat               SumatraPDF 取得           uninstall.bat        登録解除
  allow_digisma_downloads.bat   Chrome の自動ダウンロード許可だけを入れ直す
