# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

NVIDIA Jetson などの Linux 環境向けの個人用 Bash ユーティリティスクリプト集。  
**目的は2つ**：
1. シェルスクリプト開発者が、コマンド入力を簡素化するスクリプトを、短時間でデバッグ手戻り少なく実装するための道具（テンプレート・共通ライブラリ）を提供する
2. git ワークフロー・ROS2 操作・プロセス管理などの典型的な開発作業を短コマンドで実行する支援ツールを提供する

## スクリプトの実行

全スクリプトは単体で実行可能。直接呼び出す：

```bash
./git/verup.sh --help
./util/ps_util.sh -s
./bkup.sh <directory>
```

ビルドシステム・テストスイート・CI/CD パイプラインは存在しない。

## コアライブラリ：`benlib.sh`

`benlib.sh` は共通ライブラリ。全スクリプトから source して使う。

**source パターン（全スクリプト共通）：**
```bash
SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")
source "${SCRIPT_DIR}/benlib.sh"       # スクリプトがリポジトリ直下の場合
# source "${SCRIPT_DIR}/../benlib.sh"  # サブディレクトリ内の場合
set_escape_sequence
```

**提供する主な機能：**

| セクション | 関数 | 説明 |
|---|---|---|
| カラー | `set_escape_sequence` | `RED`, `CYAN`, `GRAY`, `NORM`, `CLS` 等の変数を設定 |
| カラー | `RGB <R> <G> <B>` / `BK_RGB` / `LOCATE` | 任意色・カーソル移動 |
| ログ | `echo_note/info/warning/error` | 色付きログ（error は stderr へ） |
| ログ | `show_var <VAR_NAME>` | `NAME=value` 形式でデバッグ出力 |
| エラー制御 | `enable_strict_mode` | `set -euo pipefail` + ERR トラップを設定 |
| SSH | `prepare_ssh <ADDR>` | known_hosts の古いエントリを削除 |
| SSH | `ssh_exec / ssh_rsync / rexec` | SSH 実行・ファイル同期 |
| SSH | `lexec <WAIT_OPT> <COMMAND>` | ローカル実行（gnome-terminal なし） |
| gnome-terminal | `gnome_terminal_rexec` / `gnome_terminal_lexec` | 新タブで SSH / ローカル実行 |
| 雛形 | `echo_template` / `create_scripts` | 新スクリプトのファイルを生成 |

## テンプレートの選択

| ファイル | 用途 |
|---|---|
| `template.bash` | **通常の新規スクリプトの出発点**。コピーして編集する |
| `template_exec.sh` | SSH 実行・RGB 色・カーソル操作が必要な場合の参考 |
| `template_ros.sh` | ROS2 ワークスペース自動検出・Jetson チューニングが必要な場合 |
| `template_boot.sh` | **複数ホストへの一括コマンド実行**。SEQUENCE_LIST を書き換えて使う |
| `template.sh` | 非推奨（旧形式）。`template.bash` を使うこと |

### `template_boot.sh` の SEQUENCE_LIST フォーマット

```
HOST:COMMAND:WINDOW_MODE:WAIT_OPT
```

| フィールド | 値 |
|---|---|
| HOST | `ADDR@USR@PASS`（SSH）/ `localhost`（ローカルタブ）/ `.`（直接実行） |
| COMMAND | 実行コマンド（`:` を含めないこと） |
| WINDOW_MODE | `k`=開いたまま / `e`=成功時に閉じる / `f`=常に閉じる |
| WAIT_OPT | `w`=完了まで待機 / `0`=待機なし / `N`=N 秒後に次へ |

行頭 `#` はコメント。インラインコメントも `#` 以降を無視する。  
`on_all_success` / `on_any_failure` 関数をオーバーライドして完了後処理を記述する。

## ブランチモデル

`git/verup.sh` が強制する git-flow ライクな構造：

| ブランチパターン | 用途 |
|---|---|
| `rel-X.Y.Z` | リリース（安定・クリーン） |
| `dev-X.Y.Z` | 開発統合 |
| `f-X.Y.Z-<feature>` | フィーチャーブランチ |

**バージョンアップフロー**（`git/verup.sh`）：現在のブランチ種別とワーキングツリーの状態を検出し、ブランチ作成・ステージング・コミット・マージ・バージョン更新を担うフェーズ（0〜8）を順に実行する。`-p <phase>` で指定フェーズで停止できる。

**補助 git スクリプト：**
- `git/check_head_branch2.sh` — 全サブモジュールの現在ブランチを再帰的に色付き表示（シアン = rel、黄 = dev）
- `git/submodule_switch2.sh` — 全サブモジュールをピンされたコミットに対応するブランチへ切り替える
- `git/git_tag_recursive.sh -t <tag> -m <msg>` — リポジトリと全サブモジュールに git タグを付与する
- `git/is_rel_state.sh` — リポジトリがダーティまたは `rel-*` ブランチ以外にいる場合に警告を表示（zenity またはターミナル）

## ROS2 ヘルパー（`ros/`）

- `auto_decomp.sh` — `sensor_msgs/msg/CompressedImage` トピックを全検索し、`image_transport` で raw として再配信する。SIGINT 受信時に子プロセスをクリーンに終了させる。
- `component_monitor.sh` — `ros2 component list` を画面リフレッシュしながら継続ポーリングする。

## ユーティリティスクリプト

- `util/ps_util.sh` — プロセスのスナップショット/差分/kill ユーティリティ。`-s` でスナップショット取得、オプションなしで新規プロセス表示、`-k` で新規プロセスを kill、`-c` で一時ファイルを削除。`-n <name>` で複数スナップショットの名前空間を分けられる。
- `bkup.sh <dir> [suffix]` — ディレクトリのタイムスタンプ付き `.tar.gz` を作成し、現在の git ブランチ名をファイル名に付加する。

## スタイル規約

- `main()` 関数を定義し、末尾で `main "$@"` として呼び出す
- 関数内の変数は `local` で宣言する（グローバル汚染を防ぐ）
- カラーコードは `$(printf …)` を使用（バッククォート記法 `` `printf …` `` は非推奨）
- オプション解析は `getopt`（長オプション対応）またはマニュアルの `while`/`case` ループを使い、常に `--help` を実装する
- `SCRIPT_DIR` と `THIS_SCRIPT` は `main()` の冒頭で `BASH_SOURCE[0]` を使って設定する
- `benlib.sh` の関数・変数との名前衝突を避けるため、内部ヘルパーには `_` プレフィックスを付ける（例: `_run_sequences`）
