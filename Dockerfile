# SaladCloud 用 ComfyUI API イメージ（P-H3-Image お仕置き画像見直し用）
# 公式イメージに manifest.yaml を同梱しただけの最小構成。
# モデル本体はイメージに入れず、起動時に manifest が Hugging Face から取得する。
FROM ghcr.io/saladtechnologies/comfyui-api:comfy0.7.0-api1.16.1-torch2.8.0-cuda12.8-runtime

COPY manifest.yaml .
ENV MANIFEST=manifest.yaml
