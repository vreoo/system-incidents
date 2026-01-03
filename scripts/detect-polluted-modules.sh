#!/usr/bin/env bash
set -euo pipefail

QUARANTINE=false
if [[ "${1-}" == "--quarantine" ]]; then
  QUARANTINE=true
fi

echo "Detecting polluted Realtek module trees in /lib/modules..."

found_any=0
for kdir in /lib/modules/*/kernel/drivers/net/wireless/realtek/rtw88; do
  [[ -d "$kdir" ]] || continue
  echo "Kernel module dir: $kdir"
  pushd "$kdir" >/dev/null
  # list families
  ls rtw_*.ko 2>/dev/null || true
  ls rtw88_*.ko.xz 2>/dev/null || true

  # check for both present
  shopt -s nullglob
  legacy=(rtw_*.ko)
  modern=(rtw88_*.ko.xz)
  shopt -u nullglob

  if (( ${#legacy[@]} > 0 && ${#modern[@]} > 0 )); then
    echo "--> POLLUTION DETECTED: both legacy (rtw_*.ko) and modern (rtw88_*.ko.xz) files exist"
    found_any=1
    echo "Legacy files:"
    printf ' - %s\n' "${legacy[@]}"
    echo "Modern compressed files:"
    printf ' - %s\n' "${modern[@]}"

    if $QUARANTINE; then
      qdir="/root/rtw-quarantine-$(date +%Y%m%d-%H%M%S)"
      sudo mkdir -p "$qdir"
      for f in "${legacy[@]}"; do
        echo "Quarantining $f -> $qdir/"
        sudo mv "$f" "$qdir/"
      done
      echo "Quarantine complete: $qdir"
      echo "Running depmod -a..."
      sudo depmod -a
      echo "Attempting to load rtw88_8822ce as a smoke test..."
      sudo modprobe rtw88_8822ce || true
    else
      echo "Run with --quarantine to move legacy modules into a quarantine directory (reversible)."
    fi
  else
    echo "No pollution detected for this kernel dir (looks clean)."
  fi
  popd >/dev/null
done

if (( found_any == 0 )); then
  echo "No polluted module trees found."
else
  echo "One or more polluted trees detected. Consider running the script with --quarantine to fix them safely."
fi

exit 0
