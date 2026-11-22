# SaladCloud 用 ComfyUI API イメージ（P-H3-Image お仕置き画像見直し用）v2
#
# 公式の prebuilt（comfy0.7.0）には P-H3-Image 用ノード（PH3ImageConditioning 等）が
# 含まれていなかったため、Salad 公式の docker/comfyui.dockerfile の構成をそのまま使い、
# ComfyUI を v0.45.5（P-H3 ネイティブ対応は 0.44.0 以降）に差し替えて自前ビルドする。
# torch/cuda は Salad ノードで実績のある 2.8.0 / 12.8 の組み合わせを維持する。
# モデル本体はイメージに入れず、起動時に manifest.yaml が Hugging Face から取得する。
ARG base=runtime
ARG pytorch_version=2.8.0
ARG cuda_version=12.8

FROM pytorch/pytorch:${pytorch_version}-cuda${cuda_version}-cudnn9-${base}

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
# PyTorch's newer images use Ubuntu's externally managed system Python.
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV UV_BREAK_SYSTEM_PACKAGES=1
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  curl \
  git \
  unzip \
  wget \
  && apt clean -y && rm -rf /var/lib/apt/lists/*

# Install comfy-cli, which makes it easy to install custom nodes and other comfy specific functionality.
SHELL ["/bin/bash", "-c"]

RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir uv
RUN uv pip install --no-cache-dir --system "comfy-cli==1.5.1" "huggingface_hub[cli]"

WORKDIR /opt

ARG comfy_version=0.45.5

RUN git clone --depth 1 --branch v${comfy_version} https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /opt/ComfyUI

ARG cuda_version=12.8
ARG torchaudio_version=2.8.0

# Preserve the base image's Torch/CUDA versions when installing dependencies.
RUN python -c 'import importlib.metadata as m; print("\n".join(f"{p}=={m.version(p)}" for p in ("torch", "torchvision")))' > /opt/pytorch-constraints.txt
RUN uv pip install --no-cache-dir --system -c /opt/pytorch-constraints.txt "torchaudio==${torchaudio_version}" --index-url https://download.pytorch.org/whl/cu${cuda_version//./}
RUN python -c 'import importlib.metadata as m; print("torchaudio==" + m.version("torchaudio"))' >> /opt/pytorch-constraints.txt
RUN uv pip install --no-cache-dir --system -c /opt/pytorch-constraints.txt -r requirements.txt

ENV COMFY_HOME=/opt/ComfyUI

RUN comfy --skip-prompt tracking disable
RUN comfy --skip-prompt set-default ${COMFY_HOME}

RUN git clone https://github.com/Comfy-Org/ComfyUI-Manager.git ./custom_nodes/ComfyUI-Manager
RUN uv pip install --system --no-cache-dir -c /opt/pytorch-constraints.txt -r ./custom_nodes/ComfyUI-Manager/requirements.txt

ENV MODEL_DIR=${COMFY_HOME}/models
ENV OUTPUT_DIR=${COMFY_HOME}/output
ENV INPUT_DIR=${COMFY_HOME}/input
ENV CMD="comfy --workspace ${COMFY_HOME} launch -- --listen *"
ENV BASE=""

# --- comfyui-api wrapper (公式 docker/api.dockerfile 相当) ---
ENV WORKFLOW_DIR=/workflows
ENV STARTUP_CHECK_MAX_TRIES=30

ARG api_version=1.19.2

ADD https://github.com/SaladTechnologies/comfyui-api/releases/download/${api_version}/comfyui-api .

RUN chmod +x comfyui-api

# --- P-H3 モデル manifest（起動時に取得） ---
COPY manifest.yaml .
ENV MANIFEST=manifest.yaml

CMD ["./comfyui-api"]
