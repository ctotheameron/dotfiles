# 4K@120 + HDR on the LG TV (AMD RX 9070 XT, Omarchy/Arch)

Goal: drive the LG TV at **3840x2160@120 with 10-bit HDR** (and, for gaming, **VRR**) over HDMI.

## Current status

- **HDR at 4K@60 is enabled now** — `arch/.config/hypr/monitors.conf` has
  `bitdepth, 10, cm, hdr` on the LG line. Verify with
  `hyprctl monitors all | grep -iE 'currentFormat|colorManagementPreset'`
  (expect `XRGB2101010` / `hdr`). No kernel change needed for this.
- **4K@120 is not yet active** — see the two paths below.

## Which 120Hz path to use

- **Option A — DP→HDMI 2.1 adapter (recommended, esp. for gaming): keeps VRR**, no kernel
  change. Costs an adapter.
- **Option B — FRL kernel (`linux-mainline` + boot flag): no extra hardware, but disables
  VRR** until AMD ships VRR-over-FRL in a later kernel.

## Why it doesn't work out of the box

- The TV is HDMI 2.1 and advertises 4K@120 (`VIC 118`, 1188 MHz) + HDR in its EDID.
- 4K@120 at full chroma needs **HDMI 2.1 FRL** (~32-48 Gbps). HDMI 2.0/TMDS caps at 4K@60.
- The TV's `YCbCr 4:2:0 Capability Map` does **not** include 4K@120 — only 4K@60/50 — so the
  "4:2:0 over HDMI 2.0" trick (what many TVs/Steam Machine use) cannot deliver 4K@120 here.
- The open `amdgpu` driver historically couldn't do HDMI 2.1 FRL (HDMI Forum licensing).
  **Fixed in mainline Linux 7.2** (FRL + DSC merged 2026), but **disabled by default**.
- The RX 9070 XT (DCN 4.0.1) is the reference card the FRL work was tested on.

## Option B — FRL kernel route (no extra hardware; loses VRR)

### Prerequisites (all three required)

1. **Kernel >= 7.2 with amdgpu FRL.** Arch stable is still 7.0.x, so install a newer kernel.
2. **Boot flag** `amdgpu.dc_feature_mask=0x400` (FRL is off by default until VRR lands).
3. **Ultra High Speed (HDMI 2.1, 48 Gbps certified) cable.** The old cable carries the EDID
   fine but won't sustain the FRL link.

## Procedure

### 1. Install a 7.2+ kernel (coexists with `linux` as a fallback)

```sh
yay -S linux-mainline linux-mainline-headers
pacman -Q linux-mainline            # confirm version >= 7.2
```

Limine auto-generates a separate UKI boot entry; the stock `linux` entry stays as fallback,
and btrfs snapshots give additional rollback.

### 2. Enable FRL via the kernel cmdline (Limine-managed)

Edit `/etc/default/limine` and append the flag to the default cmdline. Prefer OR-ing the
FRL bit (`0x400`) into the kernel's existing default mask rather than setting it bare
(a bare value overrides and disables other stable DC features):

```sh
# On the 7.2 kernel, read the default first:
cur=$(cat /sys/module/amdgpu/parameters/dc_feature_mask)   # e.g. some hex/dec value
printf 'amdgpu.dc_feature_mask=0x%x\n' "$(( ${cur:-0} | 0x400 ))"
```

Add a line to `/etc/default/limine`:

```sh
KERNEL_CMDLINE[default]+=" amdgpu.dc_feature_mask=0x<computed-value>"
```

Then regenerate the bootloader/UKI:

```sh
sudo limine-update
```

NOTE: do **not** hand-edit `/boot/limine.conf` — it's generated, and `omarchy-refresh-limine`
resets it. `/etc/default/limine` is the durable source.

### 3. Boot the 7.2 kernel + new cable, then verify

```sh
# replace SIG with the newest dir under /run/user/1000/hypr/
HYPRLAND_INSTANCE_SIGNATURE=SIG hyprctl monitors all | grep -A2 availableModes
```

Confirm `3840x2160@120` now appears. Then swap the monitor line in
`arch/.config/hypr/monitors.conf`:

```
monitor = desc:LG Electronics LG TV, 3840x2160@120, auto, 2, bitdepth, 10, cm, hdr
```

Reload Hyprland (`hyprctl reload` from inside the session, or System > Relaunch).

## Caveats / rollback

- FRL is experimental; **VRR does not work while FRL is enabled** (the reason it's off by
  default). Drop the boot flag to revert.
- If the new kernel misbehaves, pick the stock `linux` entry (or a snapshot) at the Limine menu.
- HDR on Wayland is still rough; SDR content can look washed out. Remove `bitdepth, 10, cm, hdr`
  to go back to SDR 4K@120 (still needs FRL) or SDR 4K@60.

## Option A — DP→HDMI 2.1 adapter (recommended for gaming; keeps VRR)

DisplayPort is unrestricted on amdgpu, so an active **DP 1.4 (DSC) → HDMI 2.1** adapter carries
full HDMI-2.1 bandwidth and — unlike FRL — can preserve **VRR**. Wiring: 9070 XT DP → adapter →
Ultra High Speed HDMI cable → TV. Works on the current kernel (no `linux-mainline`).

Adapter to buy (Shopee/Lazada MY, UGREEN official store): **UGREEN DisplayPort 1.4 → HDMI 2.1
"8K" active adapter** — the revision whose specs list **VRR**. Required specs: Active, DP 1.4 +
**DSC 1.2a**, HDMI 2.1, 8K@60 / **4K@120**, **VRR**, HDR10, HDCP 2.3. Community-validated for
4K@120 + HDR + VRR on RX 9070 + LG TVs (Bazzite). Avoid cheap passive DP→HDMI dongles (they cap
bandwidth / drop audio). Buy the newest revision — older units may need a Windows firmware update
for VRR.

Steps once it arrives:
1. Plug it in; confirm `hyprctl monitors all` lists `3840x2160@120`.
2. Set the monitor line to `3840x2160@120, auto, 2, bitdepth, 10, cm, hdr, sdrbrightness, 1.2,
   sdrsaturation, 0.98`; `hyprctl reload`.
3. VRR check: `hyprctl monitors all | grep -i vrr`. If off, apply an **EDID override** — export
   the TV EDID, strip the HDMI-2.1 block, add the FreeSync range, drop the `.bin` in
   `/usr/lib/firmware/edid/`, add `drm.edid_firmware=DP-<n>:edid/<file>` to
   `KERNEL_CMDLINE[default]` in `/etc/default/limine`, then `sudo limine-update` + reboot.
4. Audio: the sink renames to a **DisplayPort** output — re-select with
   `wpctl set-default <id>` (find it via `wpctl status`). No HDMI-CEC/eARC over the adapter.

Caveats: some units need a replug on cold boot; CEC/eARC don't pass through.

## Sources

- Phoronix — Initial AMDGPU HDMI 2.1 FRL merged for Linux 7.2
- Phoronix — AMDGPU FRL disabled-by-default (`dc_feature_mask=0x400`)
- GamingOnLinux — experimental amdgpu HDMI 2.1 FRL/DSC
- Kernel docs — amdgpu module parameters (`dc_feature_mask`)
