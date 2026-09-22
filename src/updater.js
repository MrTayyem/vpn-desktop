import { check } from '@tauri-apps/plugin-updater';
import { relaunch } from '@tauri-apps/plugin-process';

/**
 * Checks the update endpoint configured in tauri.conf.json (plugins.updater.endpoints) and, if a
 * newer signed build is available, downloads and installs it, then relaunches — the whole
 * reason for wiring this up: no more "download a new installer and run it again" for every
 * release.
 */
export async function checkForUpdate(onProgress) {
  const update = await check();
  if (!update?.available) {
    return { available: false };
  }

  await update.downloadAndInstall((event) => {
    if (onProgress) onProgress(event);
  });
  await relaunch();
  return { available: true }; // unreachable after relaunch, kept for callers/tests
}
