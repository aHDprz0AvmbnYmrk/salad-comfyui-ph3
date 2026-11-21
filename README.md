# salad-comfyui-ph3 イメージ置き場

SaladCloud で P-H3-Image（お仕置き画像見直し）を使うためのコンテナイメージを、
GitHub Actions でビルドして GHCR に置くためのファイル一式です。

## 中身

- `Dockerfile` — 公式 ComfyUI API イメージに manifest を同梱したもの
- `manifest.yaml` — 起動時に取得するモデル4点（P-H3-Image w4a8 一式、約26.8GB）の指定
- `.github/workflows/build-image.yml` — push すると自動でビルドして GHCR へ送る

イメージ自体に秘密情報は入っていません（manifest は公開URLの指定だけです）。

## 手順（九十九さま）

1. GitHub で新しいリポジトリを作成（名前は `salad-comfyui-ph3` を想定。公開・非公開どちらでも可）
2. このフォルダの中身を、そのままの構成でアップロードして commit（push）
   - `.github/workflows/build-image.yml` の置き場所が要ります。ウェブ画面のアップロードで
     フォルダごとドラッグすると構成が保たれます
3. リポジトリの Actions タブで「Build and push image to GHCR」が成功するのを確認
4. GHCR のパッケージを **Public** に変更する
   - GitHub のプロフィール → Packages → `salad-comfyui-ph3` → Package settings →
     Change visibility → Public
   - Salad 側から認証なしで引けるようにするためです。イメージに秘密は入っていません
5. イメージのアドレス（`ghcr.io/<ユーザー名>/salad-comfyui-ph3:latest`）を黒峰へ伝える

## その後（黒峰側）

- デプロイ用スクリプト（ネットワーキング付きのグループ作成、アクセスURLの取得、
  モデル取得時間と生成応答の実測）を用意して渡します
