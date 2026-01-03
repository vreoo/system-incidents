**Title:** Interrupted Fedora upgrade + DKMS Realtek driver -> `Exec format error` on kernel 6.17.13 (rtw8822ce)

**Date:** [fill timestamp]

**Systems impacted:** Laptop (Wi‑Fi), briefly sound and brightness on some kernels

**Timeline (example):**
1. *T0* — Started Fedora upgrade; upgrade was interrupted (power/network/apt/whatever).
2. *T+?* — System rebooted into mixed state; `kernel` updated but `kernel-modules` or related steps incomplete.
3. *T+?* — User had previously installed external Realtek driver (DKMS or manual), which placed uncompressed `rtw_*.ko` files in module tree for new kernel.
4. *T+?* — Kernel preferences caused legacy `.ko` to be selected over compressed `.ko.xz` in-tree modules.
5. *T+?* — Attempting to load produced `Exec format error` / `.gnu.linkonce.this_module` messages; network unavailable.

**Root cause:** A combination of an interrupted upgrade and leftover external (DKMS/manual) Realtek modules produced a polluted module tree where incompatible uncompressed legacy modules shadowed the in-tree compressed modules. The kernel attempted to load the incompatible module blob and failed with `Exec format error`.

**Immediate remediation:**
- Removed DKMS package and deleted manual driver dir.
- Quarantined legacy `rtw_*.ko` files from `/lib/modules/<kernel>/.../rtw88`.
- Ran `depmod -a` and `modprobe rtw88_8822ce` to bring up the in-tree driver.
- Verified firmware, dmesg, and NetworkManager connectivity.

**Long-term prevention:**
- Avoid installing out-of-tree Wi‑Fi drivers; rely on kernel-provided drivers where possible.
- If DKMS is necessary, only enable it when the kernel ABI is stable and Secure Boot isn’t preventing signatures.
- Always keep at least 2 kernels installed before running kernel upgrades.
- If upgrade is interrupted, do **not** attempt to patch drivers; boot older kernel and fix package set (remove broken kernel, reinstall cleanly).

**Action items:**
- Add a cron or systemd-timer that runs a light version of the detection script after each kernel update (optional).
- Consider adding a CI check in your local maintenance steps to ensure `/lib/modules/<new-kernel>/kernel/drivers/net/wireless/realtek` contains only `rtw88_*.ko.xz` on Fedora systems.
- Save this post-mortem to the device incident log and (optionally) share in Fedora infra/dev list if you think packaging needs attention.
