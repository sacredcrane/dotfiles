#!/bin/sh

cpu_first="$(
  awk '/^cpu / {
    idle = $5 + $6
    total = 0
    for (i = 2; i <= NF; i++) total += $i
    print total, idle
    exit
  }' /proc/stat
)"
sleep 0.2
cpu_second="$(
  awk '/^cpu / {
    idle = $5 + $6
    total = 0
    for (i = 2; i <= NF; i++) total += $i
    print total, idle
    exit
  }' /proc/stat
)"

set -- $cpu_first
cpu_total_first=$1
cpu_idle_first=$2
set -- $cpu_second
cpu_total_second=$1
cpu_idle_second=$2
cpu_delta=$((cpu_total_second - cpu_total_first))
idle_delta=$((cpu_idle_second - cpu_idle_first))
if [ "$cpu_delta" -gt 0 ]; then
  cpu_usage=$((100 * (cpu_delta - idle_delta) / cpu_delta))
else
  cpu_usage=0
fi

set -- $(
  awk '
    /^MemTotal:/ { total = $2 }
    /^MemAvailable:/ { available = $2 }
    END {
      used = total - available
      printf "%d %d %d", used * 100 / total, used / 1024, total / 1024
    }
  ' /proc/meminfo
)
ram_usage=$1
ram_used=$2
ram_total=$3

set -- $(
  df -Pk / |
    awk 'NR == 2 {
      gsub(/%/, "", $5)
      printf "%d %d %d", $5, $3 / 1024, $2 / 1024
    }'
)
disk_usage=$1
disk_used=$2
disk_total=$3

read -r load_1 load_5 load_15 _ < /proc/loadavg
uptime_seconds="$(cut -d. -f1 /proc/uptime)"
uptime_days=$((uptime_seconds / 86400))
uptime_hours=$(((uptime_seconds % 86400) / 3600))
uptime="${uptime_days}d ${uptime_hours}h"

cpu_temp=0
nvme_temp=0
for hwmon in /sys/class/hwmon/hwmon*; do
  [ -r "$hwmon/name" ] || continue
  name="$(cat "$hwmon/name")"
  temp="$(cat "$hwmon/temp1_input" 2>/dev/null || printf 0)"
  case "$temp" in '' | *[!0-9]*) temp=0 ;; esac

  case "$name" in
  k10temp) cpu_temp=$((temp / 1000)) ;;
  nvme) nvme_temp=$((temp / 1000)) ;;
  esac
done

amd_available=false
amd_usage=0
amd_vram_used=0
amd_vram_total=0
amd_temp=0
for card in /sys/class/drm/card*; do
  [ -e "$card/device/driver" ] || continue
  [ "$(basename "$(readlink -f "$card/device/driver")")" = "amdgpu" ] || continue
  amd_available=true
  amd_usage="$(cat "$card/device/gpu_busy_percent" 2>/dev/null || printf 0)"
  amd_vram_used="$(cat "$card/device/mem_info_vram_used" 2>/dev/null || printf 0)"
  amd_vram_total="$(cat "$card/device/mem_info_vram_total" 2>/dev/null || printf 0)"
  amd_temp="$(cat "$card/device/hwmon"/hwmon*/temp1_input 2>/dev/null || printf 0)"
  amd_vram_used=$((amd_vram_used / 1048576))
  amd_vram_total=$((amd_vram_total / 1048576))
  amd_temp=$((amd_temp / 1000))
  break
done

nvidia_available=false
nvidia_name="NVIDIA"
nvidia_usage=0
nvidia_vram_used=0
nvidia_vram_total=0
nvidia_temp=0
nvidia_power=0
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia_values="$(
    nvidia-smi \
      --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw \
      --format=csv,noheader,nounits 2>/dev/null |
      head -n 1 |
      tr -d ' '
  )"
  if [ -n "$nvidia_values" ]; then
    old_ifs=$IFS
    IFS=,
    set -- $nvidia_values
    IFS=$old_ifs
    nvidia_available=true
    nvidia_usage=${1:-0}
    nvidia_vram_used=${2:-0}
    nvidia_vram_total=${3:-0}
    nvidia_temp=${4:-0}
    nvidia_power=${5:-0}
    nvidia_name="$(
      nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null |
        head -n 1
    )"
  fi
fi

processes="$(
  ps -eo comm=,%cpu=,%mem= --sort=-%cpu |
    awk 'NR <= 5 { print $1 "\t" $2 "\t" $3 }' |
    jq -Rsc '
      split("\n")
      | map(
          select(length > 0)
          | split("\t")
          | {name: .[0], cpu: (.[1] | tonumber), mem: (.[2] | tonumber)}
        )
    '
)"

jq -cn \
  --arg uptime "$uptime" \
  --argjson cpu_usage "$cpu_usage" \
  --argjson cpu_temp "$cpu_temp" \
  --arg load_1 "$load_1" \
  --arg load_5 "$load_5" \
  --argjson ram_usage "$ram_usage" \
  --argjson ram_used "$ram_used" \
  --argjson ram_total "$ram_total" \
  --argjson disk_usage "$disk_usage" \
  --argjson disk_used "$disk_used" \
  --argjson disk_total "$disk_total" \
  --argjson nvme_temp "$nvme_temp" \
  --argjson amd_available "$amd_available" \
  --argjson amd_usage "$amd_usage" \
  --argjson amd_vram_used "$amd_vram_used" \
  --argjson amd_vram_total "$amd_vram_total" \
  --argjson amd_temp "$amd_temp" \
  --argjson nvidia_available "$nvidia_available" \
  --arg nvidia_name "$nvidia_name" \
  --argjson nvidia_usage "$nvidia_usage" \
  --argjson nvidia_vram_used "$nvidia_vram_used" \
  --argjson nvidia_vram_total "$nvidia_vram_total" \
  --argjson nvidia_temp "$nvidia_temp" \
  --arg nvidia_power "$nvidia_power" \
  --argjson processes "$processes" \
  '{
    uptime: $uptime,
    cpu: {usage: $cpu_usage, temp: $cpu_temp, load1: $load_1, load5: $load_5},
    ram: {usage: $ram_usage, used: $ram_used, total: $ram_total},
    disk: {usage: $disk_usage, used: $disk_used, total: $disk_total, temp: $nvme_temp},
    amd: {
      available: $amd_available,
      usage: $amd_usage,
      vram_used: $amd_vram_used,
      vram_total: $amd_vram_total,
      temp: $amd_temp
    },
    nvidia: {
      available: $nvidia_available,
      name: $nvidia_name,
      usage: $nvidia_usage,
      vram_used: $nvidia_vram_used,
      vram_total: $nvidia_vram_total,
      temp: $nvidia_temp,
      power: $nvidia_power
    },
    processes: $processes
  }'
