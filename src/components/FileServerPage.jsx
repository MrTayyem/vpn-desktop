import React from 'react';
import TitleBar from './TitleBar.jsx';
import { FileServerIcon } from './icons.jsx';

export default function FileServerPage() {
  return (
    <>
      <TitleBar />
      <div className="page">
        <div className="page-header">
          <h2>File Server</h2>
          <p>Access files on your network storage through the VPN.</p>
        </div>
        <div className="placeholder-card">
          <span className="placeholder-badge">Coming soon</span>
          <div className="icon"><FileServerIcon /></div>
          <h3>Not built yet</h3>
          <p>This is a placeholder for a future feature — browsing/transferring files to a server over the VPN connection. No backend for this exists yet.</p>
        </div>
      </div>
    </>
  );
}
