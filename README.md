# TayyemVPN Desktop (Windows)

A native Windows desktop app (React UI inside a Tauri/Rust shell — not a website, not Electron)
for connecting to the Tayyem VPN, with split tunneling (per-app and per-destination) and
in-place auto-updates.

## Status: working prototype, not yet verified on real Windows hardware

This was built entirely from a macOS/Linux dev environment with **no Rust toolchain and no
Windows machine available** to compile or run any of it. Concretely, that means:

| Piece | Confidence | Why |
|---|---|---|
| Login against `tayyem_platform` | High | Plain HTTP JSON, same as every other client on the platform |
| React UI | High | Built and verified with `npm run build` from this repo |
| OpenVPN process + management-interface control | Medium-high | Standard process spawning + a documented text protocol over TCP, but never run against a real `openvpn.exe` |
| Destination-based split tunneling (`route`) | Medium-high | Standard Windows `Get-NetRoute`/`New-NetRoute` PowerShell cmdlets |
| Auto-updater | Medium | Tauri's official plugin, but needs a real signing key + a real hosted manifest to test end-to-end |
| Per-app split tunneling (WinDivert) | **Low — needs real testing** | Raw FFI into `WinDivert.dll`'s C ABI with hand-written struct byte offsets (`src-tauri/src/split_tunnel/windivert.rs`). This is the one piece most likely to need debugging on actual Windows hardware. If it's wrong, everything else in the app still works — destination-based split tunneling and the VPN connection don't depend on it. |

**First thing to do on a real Windows machine:** `npm install`, then `npm run tauri dev`, and try
connecting. If per-app split tunneling doesn't actually redirect traffic, start by instrumenting
`windivert.rs`'s byte offsets against the actual `WinDivert.h` for whatever WinDivert version you
downloaded.

## Requirements

- Windows 10/11
- [Rust + Cargo](https://rustup.rs)
- [Node.js](https://nodejs.org) 18+
- [Tauri CLI prerequisites](https://tauri.app/start/prerequisites/) (WebView2 — usually already
  present on Windows 11; Visual Studio Build Tools with the "Desktop development with C++"
  workload)
- The **community OpenVPN client** from [openvpn.net](https://openvpn.net/community-downloads/)
  installed at its default path (`C:\Program Files\OpenVPN\bin\openvpn.exe`) — **not** OpenVPN
  Connect, which has no management interface for this app to drive
- (Optional, for per-app split tunneling) [WinDivert](https://github.com/basil00/WinDivert) — see
  `resources/windivert/README.md`

## Develop

```
npm install
npm run tauri dev
```

## Build an installer

```
npm run tauri build
```

Produces an NSIS installer under `src-tauri/target/release/bundle/nsis/`. The app requests
Administrator elevation on launch (`src-tauri/app.manifest`) — split tunneling needs to edit the
routing table and (for per-app rules) open a WinDivert handle, both of which require it.

## CI builds — you never have to build this locally

**Currently using Azure Pipelines** (`azure-pipelines.yml`), not the GitHub Actions workflow
below — GitHub Actions was blocked by an account-level billing lock unrelated to this project.
`.github/workflows/build.yml` is left in place for whenever that's resolved; it's equivalent.

### Azure Pipelines (active)

1. Create a free org at [dev.azure.com](https://dev.azure.com) (Microsoft account — separate
   billing from GitHub entirely).
2. New Project → Pipelines → Create Pipeline → GitHub → authorize access → select the
   `vpn-desktop` repo. Azure auto-detects `azure-pipelines.yml` at the repo root and runs it.
3. Every push to `main` now builds on a real Windows VM and publishes the installer as a
   downloadable pipeline artifact (Pipelines → the run → Artifacts). This is genuinely the
   fastest way to find out whether the Rust code (especially `windivert.rs`) actually compiles.
4. For a **signed** release build, add two secret pipeline variables (Pipeline → Edit →
   Variables): `TAURI_SIGNING_PRIVATE_KEY` (full contents of the key file from
   `npx @tauri-apps/cli signer generate`) and `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`. Then push a
   tag: `git tag app-v0.1.0 && git push origin app-v0.1.0`.
5. Put the signer's printed **public** key into `src-tauri/tauri.conf.json`'s
   `plugins.updater.pubkey` (replacing `REPLACE_ME_...`) and commit/push.

Note: this Azure setup only gets you a **downloadable installer per build** — it does not
automatically publish a GitHub Release or `latest.json` the way the GitHub Actions path (via
`tauri-apps/tauri-action`) does. Wiring the in-app auto-updater to check against an
Azure-published artifact instead of a GitHub Release is a follow-up, not done yet.

### GitHub Actions (blocked by billing, kept for later)

1. **Create the repo** (from inside this `vpn-desktop/` folder):
   ```
   git init
   git add .
   git commit -m "Initial commit"
   ```
   Then create an empty repo at github.com/new named `vpn-desktop` under your account, and:
   ```
   git remote add origin https://github.com/mrtayyem/vpn-desktop.git
   git branch -M main
   git push -u origin main
   ```
   (Swap `mrtayyem` for your actual GitHub username if different — also update it in
   `src-tauri/tauri.conf.json`'s `plugins.updater.endpoints` if so.)

2. **Every push now builds automatically** and Actions will tell you (green check / red X) if it
   compiles — including the parts I couldn't verify myself. This is genuinely the fastest way
   to find out whether the Rust code (especially `windivert.rs`) actually compiles.

3. **To cut a real, installable, auto-updating release:**
   - Generate a signing keypair once: `npx @tauri-apps/cli signer generate -w ~/.tauri/tayyem-vpn.key`
   - Put the printed **public** key into `src-tauri/tauri.conf.json`'s `plugins.updater.pubkey`
     (replacing the `REPLACE_ME_...` placeholder), commit, push.
   - In the GitHub repo's Settings → Secrets and variables → Actions, add two secrets:
     `TAURI_SIGNING_PRIVATE_KEY` (the full contents of the private key file) and
     `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` (the password you set when generating it).
   - Push a tag: `git tag app-v0.1.0 && git push origin app-v0.1.0`
   - Actions builds, signs, and publishes a **draft** GitHub Release with the installer and the
     `latest.json` the auto-updater checks against. Review it, hit "Publish release" — from then
     on, anyone running an older version gets offered the update automatically.

Until you've done the signing-key step, plain pushes to `main` still build (proving the code
compiles) but don't produce a signed release, and "Check for updates" in the app will fail to
find anything — that's expected, not a bug.

## What's real vs. placeholder

- **Real**: login/entitlement check (same rules as every other Tayyem client — completed
  account, verified email, `vpn-access` grant), connect/disconnect via OpenVPN's management
  interface, destination-based split tunneling, settings persistence, the whole UI.
- **Experimental**: per-app split tunneling (see table above).
- **Placeholder only**: the "File Server" sidebar entry is a stub screen with no backend —
  added because it was asked for, not because anything exists to back it yet.
- **Not wired up**: public IP / location / ISP display on the home screen (shown as a note in
  the UI rather than faked with a fabricated value).
