import React from 'react';
import TitleBar from './TitleBar.jsx';

const SERVERS = [
  { flag: '\u{1F1E9}\u{1F1EA}', name: 'Germany', city: 'Frankfurt', host: 'eu-vpn.tayyem.dev', active: true },
  { flag: '\u{1F1FA}\u{1F1F8}', name: 'USA', city: 'Coming soon', active: false },
  { flag: '\u{1F1EC}\u{1F1E7}', name: 'UK', city: 'Coming soon', active: false },
];

export default function ServersPage({ status }) {
  return (
    <>
      <TitleBar />
      <div className="page">
        <div className="page-header">
          <h2>Servers</h2>
          <p>More locations get added here as they come online — managed from the admin panel.</p>
        </div>
        <div className="list" style={{ maxWidth: 460 }}>
          {SERVERS.map((s) => (
            <div className="list-row" key={s.name} style={{ padding: '12px 14px', opacity: s.active ? 1 : 0.5 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 20 }}>{s.flag}</span>
                <div>
                  <div style={{ fontWeight: 700 }}>{s.name}</div>
                  <div style={{ fontSize: 11.5, color: 'var(--text-faint)' }}>{s.city}</div>
                </div>
              </div>
              {s.active && status.state === 'connected' && (
                <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--success)' }}>Connected</span>
              )}
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
