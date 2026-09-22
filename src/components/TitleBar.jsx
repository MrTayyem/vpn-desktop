import React from 'react';
import { getCurrentWindow } from '@tauri-apps/api/window';
import { MinusIcon, SquareIcon, XIcon } from './icons.jsx';

export default function TitleBar() {
  const win = getCurrentWindow();
  return (
    <div className="titlebar">
      <button onClick={() => win.minimize()} title="Minimize"><MinusIcon /></button>
      <button onClick={() => win.toggleMaximize()} title="Maximize"><SquareIcon /></button>
      <button className="close" onClick={() => win.close()} title="Close"><XIcon /></button>
    </div>
  );
}
