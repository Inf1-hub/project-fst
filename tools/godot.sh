#!/usr/bin/env bash
# Linux 本地开发脚本，与 tools/godot.ps1 的任务对齐。
# 用法：tools/godot.sh [editor|run|check|test|playtest|benchmark]
# 引擎路径解析顺序：GODOT_PATH -> PATH 上的 godot -> $HOME/.local/share/godot/godot
set -euo pipefail

task="${1:-editor}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

godot_path="${GODOT_PATH:-}"
if [ -z "${godot_path}" ]; then
  if command -v godot >/dev/null 2>&1; then
    godot_path="$(command -v godot)"
  else
    godot_path="$HOME/.local/share/godot/godot"
  fi
fi
if [ ! -x "${godot_path}" ]; then
  echo "找不到 Godot 可执行文件：${godot_path}。请设置 GODOT_PATH 或先运行 .cursor/install.sh。" >&2
  exit 1
fi

expected_version="$(tr -d '[:space:]' < "${project_root}/engine.version")"
actual_version="$("${godot_path}" --version 2>/dev/null | tr -d '[:space:]')"
if [ "${actual_version}" != "${expected_version}" ]; then
  echo "引擎版本不匹配：期望 ${expected_version}，实际 ${actual_version}。" >&2
  exit 1
fi

log_dir="${project_root}/.local"
mkdir -p "${log_dir}"

# 无界面渲染需要虚拟显示器；有 DISPLAY 时直接用，否则用 xvfb-run。
gui_wrap() {
  if [ -n "${DISPLAY:-}" ]; then
    "$@"
  elif command -v xvfb-run >/dev/null 2>&1; then
    xvfb-run -a -s "-screen 0 1280x720x24" "$@"
  else
    echo "未找到 DISPLAY 或 xvfb-run，无法进行有窗口渲染。" >&2
    exit 1
  fi
}

invoke_check() {
  local name="$1"; shift
  local log_path="${log_dir}/${name}.log"
  "${godot_path}" --headless --path "${project_root}" --log-file "${log_path}" "$@"
  if grep -qE 'SCRIPT ERROR:|ERROR:' "${log_path}"; then
    echo "Godot ${name} 报告错误，详见 ${log_path}" >&2
    exit 1
  fi
}

require_marker() {
  local log_name="$1"; local marker="$2"; local message="$3"
  if ! grep -q "${marker}" "${log_dir}/${log_name}.log"; then
    echo "${message}" >&2
    exit 1
  fi
}

case "${task}" in
  editor)
    gui_wrap "${godot_path}" --path "${project_root}" --editor
    ;;
  run)
    gui_wrap "${godot_path}" --path "${project_root}"
    ;;
  check)
    invoke_check import --editor --import
    invoke_check smoke --quit-after 2
    echo 'PASS: 引擎版本、资源导入与启动。'
    ;;
  test)
    invoke_check terrain_contract --quit-after 1200 --script res://tests/terrain_contract_test.gd
    require_marker terrain_contract 'TERRAIN CONTRACT: 0 failures' '地形契约测试未完成。'
    invoke_check tactical_layout --quit-after 1200 --script res://tests/tactical_layout_test.gd
    require_marker tactical_layout 'TACTICAL TEST: 0 failures' '战术布局测试未完成。'
    invoke_check camera_test --quit-after 1200 --script res://tests/camera_test.gd
    require_marker camera_test 'CAMERA TEST: 0 failures' '相机测试未完成。'
    invoke_check room_flow --quit-after 1200 --script res://tests/room_flow_test.gd
    require_marker room_flow 'ROOM FLOW: 0 failures' '关卡流程测试未完成。'
    invoke_check mvp_test --quit-after 1200 --script res://tests/mvp_test.gd
    require_marker mvp_test 'MVP TESTS: 0 failures' 'MVP 测试未到达完成标记。'
    echo 'PASS: 全部无界面测试通过。'
    ;;
  playtest)
    invoke_check playthrough --fixed-fps 60 --quit-after 55000 --script res://tests/playthrough_test.gd
    require_marker playthrough 'PLAYTHROUGH PASS:' '自动通关未到达下一层。'
    ;;
  benchmark)
    "${godot_path}" --headless --path "${project_root}" --log-file "${log_dir}/benchmark.log" --disable-vsync --script res://tests/stress_test.gd
    ;;
  *)
    echo "未知任务：${task}。可选：editor|run|check|test|playtest|benchmark" >&2
    exit 1
    ;;
esac
