# 4K@120 + HDR on the LG TV (AMD RX 9070 XT, Omarchy/Arch)

Goal: drive the LG TV at **3840x2160@120 with 10-bit HDR** (and, for gaming,
**VRR**) over HDMI.

## What this panel can actually do (from its EDID)

Read with `edid-decode /sys/class/drm/card1-HDMI-A-1/edid`:

- **120 Hz is the hard ceiling.** The highest mode in the whole EDID is `VIC
  118: 3840x2160 120.000 Hz` (1188 MHz). There is **no 144/165/240 Hz mode at
  any resolution** — the fastest non-4K modes are 2560x1440@120 and
  1920x1080@120. **4K@240 is not achievable on this display**; that is a panel
  limit, not a driver one.
- **VRRmin 40 Hz / VRRmax 120 Hz** — so VRR is worth preserving, and it also
  tops out at 120.
- **Max TMDS Character Rate: 600 MHz** — HDMI 2.0 territory, which is exactly
  why the link currently caps at 4K@60.
- **Max Fixed Rate Link: 6, 8, 10 and 12 Gbps on 4 lanes** — the TV supports FRL
  up to 48 Gbps (full HDMI 2.1). The display side is not the blocker; the driver
  is.

## Current status

- **Desktop HDR is deliberately off** — `arch/.config/hypr/monitors.lua` drives
  the LG at plain SDR 4K@60, because `cm = "hdr"` lifts SDR blacks to grey on
  OLED (hyprwm/Hyprland#9716). *Update 2026-09-12: #9716 is closed upstream
  (2025-04), so desktop HDR is viable again — still keeping SDR by choice;
  revisit if desired.* HDR is applied per-game via gamescope instead:
  `gamescope -f --hdr-enabled -- %command%`. To try desktop HDR anyway, add
  `bitdepth = 10, cm = "hdr"` to the LG line and verify with `hyprctl monitors
  all | grep -iE 'currentFormat|colorManagementPreset'` (expect `XRGB2101010` /
  `hdr`). No kernel change needed for this.
- **4K@120 via Option B is in progress (2026-09-12)** — kernel **7.2.3**
  reached Arch core and arrived through the normal `omarchy update`
  (no AUR kernel needed). `amdgpu.dcfeaturemask=0x402` is appended to
  `/etc/default/limine` (backup: `/etc/default/limine.bak.1789205994`) and
  verified baked into the UKI (`strings /boot/EFI/Linux/omarchy_linux.efi |
  grep dcfeaturemask`). Remaining: reboot → confirm `3840x2160@120` in
  `hyprctl monitors all` → swap the monitor line in `monitors.lua`.
  Side effect of that same kernel: the HDMI output path was reworked, which
  changed perceived contrast on the TV after the update.

## Which 120Hz path to use

**Neither path gives you VRR today.** An earlier revision of this doc claimed
the adapter route preserved it — that was wrong. Cable Matters' knowledge base
states plainly *"VRR is not supported"* for its DP→HDMI 2.1 adapter; Club 3D
deliberately does not market VRR on theirs, saying stable VRR across a DP→HDMI
conversion isn't achievable consistently across GPU/chipset/display
combinations. Treat any listing claiming otherwise as marketing.

So the real comparison:

| | Option A — adapter | Option B — FRL kernel |
| --- | --- | --- |
| 4K@120 | works today | needs kernel >= 7.2 |
| VRR | **never** (protocol conversion) | not yet; arrives with FRL-by-default |
| Cost | ~RM100–200 | free |
| Native HDMI audio/CEC | lost (see below) | unchanged |
| Risk | adapter quirks, cold-boot replug | Omarchy issue #6169, see Risks |

- **Option A — DP→HDMI 2.1 adapter:** the only way to get 4K@120 *right now*.
  Permanent VRR dead end. Best unit: **Cable Matters 102101-BLK** (explicitly
  lists RX 9070 support, DP 1.4 + DSC, 4K@120). Fallback: UGREEN active DP 1.4 →
  HDMI 2.1 **with DSC 1.2a** — easier to get on Shopee/Lazada MY; ignore any VRR
  claim on the listing.
- **Option B — FRL kernel:** free, keeps the native HDMI path (audio and CEC
  unchanged), and is the **only route that ever regains VRR**. Costs a wait: 7.2
  is not released yet.

**Recommendation: wait for 7.2 final and take Option B.** The adapter's only
advantage is immediacy, and the desktop is perfectly usable at 4K@60 meanwhile.
Buy the adapter only if 4K@120 is needed before 7.2 ships.

## Why it doesn't work out of the box

- The TV is HDMI 2.1 and advertises 4K@120 (`VIC 118`, 1188 MHz) + HDR in its
  EDID.
- 4K@120 at full chroma needs **HDMI 2.1 FRL** (~32-48 Gbps). HDMI 2.0/TMDS caps
  at 4K@60.
- The TV's `YCbCr 4:2:0 Capability Map` does **not** include 4K@120 — only
  4K@60/50 — so the "4:2:0 over HDMI 2.0" trick (what many TVs/Steam Machine
  use) cannot deliver 4K@120 here.
- The open `amdgpu` driver historically couldn't do HDMI 2.1 FRL (HDMI Forum
  licensing). **Fixed in mainline Linux 7.2** (FRL + DSC merged 2026), but
  **disabled by default**.
- The RX 9070 XT (DCN 4.0.1) is the reference card the FRL work was tested on.

## Option B — FRL kernel route (no extra hardware; loses VRR)

### Prerequisites (all three required)

1. **Kernel >= 7.2 with amdgpu FRL.** ✅ **Satisfied 2026-09-12**: Arch core
   ships **7.2.3**, delivered via `omarchy update`. The `linux-mainline` AUR
   route below is obsolete — skip Procedure step 1.
2. **Boot flag** `amdgpu.dcfeaturemask=<mask>` (FRL is off by default until VRR
   lands).

   > **The parameter is `dcfeaturemask`, not `dc_feature_mask`.**
   > `dc_feature_mask` is the *C variable* name (`amdgpu_dc_feature_mask`);
   > the module parameter registered via `module_param_named()` is
   > `dcfeaturemask`. Most write-ups (and an earlier revision of this doc)
   > get this wrong, and the wrong name **fails silently** — the kernel
   > ignores the unknown parameter and you boot with FRL still off.
   > Confirm on the target kernel:
   >
   > ```sh
   > modinfo amdgpu | grep -i featuremask
   > ls /sys/module/amdgpu/parameters/ | grep -i featuremask
   > ```
   >
   > On 7.1.8 the current value is `2` (`0x2`), so the OR'd target would be
   > `0x402`.
   > Re-check on 7.2 before committing it — the default mask may differ.
3. **Ultra High Speed (HDMI 2.1, 48 Gbps certified) cable.** A marginal cable
   carries the EDID fine — EDID travels on a low-speed side channel — but won't
   sustain the FRL link, so a bad cable looks like "FRL just doesn't work"
   rather than an obvious cable fault.

   > **Already satisfied.** The PS5 runs this panel at 4K@120 today, which
   > proves both the cable and that TV port sustain a 48 Gbps FRL link. Reuse
   > that cable for the PC rather than buying another, and change one variable
   > at a time.

## Procedure

### 1. Install a 7.2+ kernel (coexists with `linux` as a fallback)

**Obsolete as of 2026-09-12** — stock `linux` is 7.2.3. No extra kernel needed
(which also sidesteps the issue #6169 risk of extra kernel/limine operations).

```sh
# yay -S linux-mainline linux-mainline-headers   # no longer needed
pacman -Q linux                     # 7.2.3-arch1-3 or newer
```

### 2. Enable FRL via the kernel cmdline (Limine-managed)

Edit `/etc/default/limine` and append the flag to the default cmdline. Prefer
OR-ing the FRL bit (`0x400`) into the kernel's existing default mask rather than
setting it bare (a bare value overrides and disables other stable DC features):

```sh
# On the 7.2 kernel, confirm the parameter name, then read its default:
modinfo amdgpu | grep -i featuremask
cur=$(cat /sys/module/amdgpu/parameters/dcfeaturemask)   # 7.1.8 default: 2
printf 'amdgpu.dcfeaturemask=0x%x\n' "$(( ${cur:-0} | 0x400 ))"   # 0x2 -> 0x402
```

Add a line to `/etc/default/limine`:

```sh
KERNEL_CMDLINE[default]+=" amdgpu.dcfeaturemask=0x<computed-value>"
```

Verify after reboot that the value actually took — a mistyped parameter name is
ignored silently, with no error anywhere:

```sh
cat /sys/module/amdgpu/parameters/dcfeaturemask   # expect the OR'd value
```

Then regenerate the bootloader/UKI:

```sh
sudo limine-update
```

NOTE: do **not** hand-edit `/boot/limine.conf` — it's generated, and
`omarchy-refresh-limine` resets it. `/etc/default/limine` is the durable source.

### 3. Boot the 7.2 kernel + new cable, then verify

```sh
# replace SIG with the newest dir under /run/user/1000/hypr/
HYPRLAND_INSTANCE_SIGNATURE=SIG hyprctl monitors all | grep -A2 availableModes
```

Confirm `3840x2160@120` now appears. Then swap the monitor line in
`arch/.config/hypr/monitors.lua`:

```lua
hl.monitor({ output = "desc:LG Electronics LG TV", mode = "3840x2160@120",
             position = "auto", scale = 2 })
```

Reload Hyprland (`hyprctl reload` from inside the session, or System >
Relaunch).

## Caveats / rollback

- FRL is experimental; **VRR does not work while FRL is enabled** (the reason
  it's off by default). Drop the boot flag to revert.
- If the new kernel misbehaves, pick the stock `linux` entry (or a snapshot) at
  the Limine menu.
- HDR on Wayland is still rough; SDR content can look washed out. Remove
  `bitdepth = 10, cm = "hdr"` to go back to SDR 4K@120 (still needs FRL) or SDR
  4K@60.

### Risk: Omarchy issue #6169 (open) — kernel updates vs LUKS + UKI

<https://github.com/basecamp/omarchy/issues/6169>

Installing a second kernel means more kernel/limine package operations, and
there is an **open** bug where exactly that leaves this class of system
unbootable:

> `:: running hook [encrypt]` / `ERROR: device not found` → dropped to
> emergency shell

The reporter's stack matches this machine closely — LUKS + Btrfs subvolumes,
Limine with `ENABLE_UKI=yes`, `encrypt` hook — and it recurred three times in a
week across routine `linux` upgrades. The fix each time was chrooting in from a
live/emergency shell and running `limine-mkinitcpio` with no config changes,
suggesting a stale UKI is left in place while the build step reports success.

Before adding a kernel, make sure recovery is actually possible:

- Have a **bootable Arch USB** on hand — recovery requires chroot, which you
  cannot do from the broken system itself.
- Confirm snapshots are present (`BOOT_ORDER` includes `Snapshots`,
  `MAX_SNAPSHOT_ENTRIES=5` in `/etc/default/limine`) and that you know the LUKS
  passphrase from cold.
- Keep the stock `linux` entry as the default boot target until 7.2 is proven on
  this machine.
- After any kernel/limine update, if boot fails: chroot in and run
  `limine-mkinitcpio`.

This risk is the strongest argument for simply waiting for 7.2 to reach Arch
`core`, where it arrives through the normal update path rather than as an extra
AUR kernel.

## Option A — DP→HDMI 2.1 adapter (works today; no VRR, ever)

DisplayPort is unrestricted on amdgpu, so an active **DP 1.4 (DSC) → HDMI 2.1**
adapter carries enough bandwidth for 4K@120 without any kernel change. Wiring:
9070 XT DP → adapter → the existing Ultra High Speed HDMI cable → TV. `DP-1` and
`DP-2` are both free; only `HDMI-A-1` is in use.

**This route cannot do VRR.** Cable Matters documents *"VRR is not supported"*;
Club 3D declines to advertise it. The protocol conversion is the problem, so no
firmware revision fixes it.

Adapter to buy, in order of preference:

1. **Cable Matters 102101-BLK** — explicitly lists **RX 9070** support, DP 1.4 +
   DSC, 4K@120. US brand, so thinner availability on Shopee/Lazada MY.
2. **UGREEN active DP 1.4 → HDMI 2.1** (official store) — easy to get locally.
   Specs to require: Active, unidirectional DP→HDMI, **DSC 1.2a**, HDMI 2.1,
   **4K@120**, HDR10, HDCP 2.3.

Ignore VRR claims on any listing. Avoid cheap passive / "DP++" / "dual-mode"
dongles — they cap bandwidth and drop audio. Buy from a Shopee Mall / official
store so it can be returned.

### Audio over the adapter

Audio **does** work: DisplayPort carries it natively and the GPU's device is a
single "Navi 48 HDMI/**DP** Audio Controller" serving both output types. Expect
multichannel LPCM. Compressed bitstream passthrough (Atmos/DTS-HD) is unreliable
through protocol converters, but PipeWire outputs LPCM by default, so this
rarely matters.

- **CEC is lost.** The adapter doesn't carry the CEC line — no PC-controls-TV,
  no TV-remote- controls-PC.
- **eARC is *not* affected.** eARC runs TV→soundbar from a separate port in the
  opposite direction; the TV forwards whatever it is playing regardless of how
  the source arrived. A soundbar/AVR setup keeps working. (An earlier revision
  of this doc lumped CEC and eARC together, which wrongly implied the adapter
  would break external speakers.)

Steps once it arrives:

1. Plug into `DP-1` (or `DP-2`) and a **second** TV HDMI port, then switch
   inputs. That way the working HDMI setup stays untouched while testing, and
   you can switch back if it doesn't come up.
2. Confirm `hyprctl monitors all` lists `3840x2160@120`.
3. Update `arch/.config/hypr/monitors.lua` to the new output and mode:

   ```lua
   hl.monitor({ output = "desc:LG Electronics LG TV", mode = "3840x2160@120",
                position = "auto", scale = 2 })
   ```

   Then `hyprctl reload`. Leave HDR off — the OLED black-level problem
   (hyprwm/Hyprland#9716) applies here exactly as it does over HDMI.
4. Audio: the sink moves to a **DisplayPort** endpoint and PipeWire won't carry
   the default across, so re-select it with `wpctl set-default <id>` (find it
   via `wpctl status`).

Do **not** bother with a VRR check or an EDID override on this route — VRR is
not supported across the protocol conversion at all, so there is nothing to
enable.

Caveats: some units need a replug on cold boot, and CEC does not pass through.

## Sources

- Phoronix — Initial AMDGPU HDMI 2.1 FRL merged for Linux 7.2
- Phoronix — AMDGPU FRL disabled-by-default (the FRL bit is `0x400`; note these
  write-ups spell the knob `dc_feature_mask`, which is the C variable, not the
  module parameter — see the warning in Prerequisites)
- GamingOnLinux — experimental amdgpu HDMI 2.1 FRL/DSC
- Kernel docs — amdgpu module parameters (`dcfeaturemask`)
- Cable Matters KB #189 — 102101/102103 adapter: "VRR is not supported"
- Club 3D Insights — why they don't advertise VRR on DP→HDMI adapters
- Omarchy issue #6169 — kernel/limine update breaks LUKS + UKI boot (open)
- This machine's EDID — `edid-decode /sys/class/drm/card1-HDMI-A-1/edid`
