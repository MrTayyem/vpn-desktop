# WinDivert files go here

Per-app split tunneling needs `WinDivert.dll` (and its matching driver, `WinDivert64.sys` /
`WinDivert32.sys`) in this folder. They are **not** included in this repo — download the official
redistributable yourself so you can verify what you're running:

1. Go to https://github.com/basil00/WinDivert/releases and download the latest `WinDivert-2.x.x-A.zip`.
2. From the zip's `x64` folder, copy these three files into this directory:
   - `WinDivert.dll`
   - `WinDivert64.sys`
   - `WinDivert.lib` (not required at runtime, but harmless to include)
3. Rebuild the app (`npm run tauri build`).

If these files are missing, the app still runs fine — destination-based (IP/domain) split
tunneling and the VPN connection itself are unaffected. Only per-app split tunneling silently
stays inactive, and a line explaining that is written to the in-app connection log.
