#!/usr/bin/env bash
# Cloud Agent 安装脚本：准备无界面 Godot 引擎并导入工程资源。
# 需保持幂等：可重复运行，不写死一次性状态。
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
expected_version="$(tr -d '[:space:]' < "${project_root}/engine.version")"

# 从 engine.version 解析下载用的版本号（形如 4.7.2.stable.official.<hash> -> 4.7.2-stable）。
version_core="$(echo "${expected_version}" | cut -d. -f1-3)"
release_tag="$(echo "${expected_version}" | awk -F. '{print $1"."$2"."$3"-"$4}')"
zip_name="Godot_v${version_core}-stable_linux.x86_64.zip"
bin_name="Godot_v${version_core}-stable_linux.x86_64"
download_url="https://github.com/godotengine/godot/releases/download/${release_tag}/${zip_name}"

install_dir="${GODOT_HOME:-$HOME/.local/share/godot}"
godot_bin="${install_dir}/godot"
bin_link_dir="$HOME/.local/bin"
bin_link="${bin_link_dir}/godot"

# 仅当缺少所需命令/库时才补装系统包，避免每次安装重复跑 apt。
need_pkgs=0
command -v xvfb-run >/dev/null 2>&1 || need_pkgs=1
command -v unzip >/dev/null 2>&1 || need_pkgs=1
command -v curl >/dev/null 2>&1 || need_pkgs=1
ldconfig -p 2>/dev/null | grep -q 'libGL\.so\.1' || need_pkgs=1
if [ "${need_pkgs}" = "1" ] && command -v sudo >/dev/null 2>&1; then
  echo "[install] 安装无界面渲染所需系统包 ..."
  sudo -n apt-get update -y >/dev/null 2>&1 && \
    sudo -n apt-get install -y --no-install-recommends \
      xvfb unzip curl libgl1 libglx-mesa0 libgl1-mesa-dri >/dev/null 2>&1 || \
    echo "[install] 跳过 apt 安装（无 sudo 权限），继续。"
fi

current_version=""
if [ -x "${godot_bin}" ]; then
  current_version="$("${godot_bin}" --version 2>/dev/null | tr -d '[:space:]' || true)"
fi

if [ "${current_version}" != "${expected_version}" ]; then
  echo "[install] 下载 Godot ${expected_version} ..."
  mkdir -p "${install_dir}"
  tmp_zip="$(mktemp --suffix=.zip)"
  curl -fsSL -o "${tmp_zip}" "${download_url}"
  unzip -o "${tmp_zip}" -d "${install_dir}" >/dev/null
  rm -f "${tmp_zip}"
  mv -f "${install_dir}/${bin_name}" "${godot_bin}"
  chmod +x "${godot_bin}"
else
  echo "[install] 已存在匹配的 Godot ${expected_version}，跳过下载。"
fi

actual_version="$("${godot_bin}" --version 2>/dev/null | tr -d '[:space:]')"
if [ "${actual_version}" != "${expected_version}" ]; then
  echo "[install] 引擎版本不匹配：期望 ${expected_version}，实际 ${actual_version}" >&2
  exit 1
fi

mkdir -p "${bin_link_dir}"
ln -sf "${godot_bin}" "${bin_link}"

# 导入资源，使 .godot 缓存就绪（无界面）。
echo "[install] 导入工程资源 ..."
"${godot_bin}" --headless --path "${project_root}" --editor --import >/dev/null 2>&1 || true

echo "[install] 完成。Godot: ${godot_bin} (${actual_version})"
