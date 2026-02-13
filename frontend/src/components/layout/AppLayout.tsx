import type { PropsWithChildren } from 'react';
import { NavLink } from 'react-router-dom';
import { useViewContext } from '@/context/ViewContext';
import type { RoleMode } from '@/types/platform';

interface AppLayoutProps extends PropsWithChildren {
  lastUpdated?: string;
  onRefresh?: () => void;
}

function RoleSwitch({ role, onChange }: { role: RoleMode; onChange: (value: RoleMode) => void }) {
  return (
    <div className="toggle-group" role="group" aria-label="Role mode">
      <button
        type="button"
        className={role === 'viewer' ? 'active' : ''}
        onClick={() => onChange('viewer')}
      >
        Viewer
      </button>
      <button
        type="button"
        className={role === 'operator' ? 'active' : ''}
        onClick={() => onChange('operator')}
      >
        Operator
      </button>
    </div>
  );
}

export function AppLayout({ children, lastUpdated, onRefresh }: AppLayoutProps): JSX.Element {
  const { role, explainMode, setExplainMode, setRole } = useViewContext();

  return (
    <div className="app-shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">FreshCloud@Home</p>
          <h1>Platform Dashboard</h1>
        </div>

        <div className="topbar-actions">
          <RoleSwitch role={role} onChange={setRole} />

          <label className="switch-control">
            <input
              type="checkbox"
              checked={explainMode}
              onChange={(event) => setExplainMode(event.target.checked)}
            />
            <span>Explain mode</span>
          </label>

          {onRefresh ? (
            <button type="button" className="ghost-button" onClick={onRefresh}>
              Refresh
            </button>
          ) : null}
        </div>
      </header>

      <nav className="main-nav" aria-label="Primary">
        <NavLink to="/" end>
          Overview
        </NavLink>
        <NavLink to="/architecture">Architecture</NavLink>
        <NavLink to="/docs">Documentation</NavLink>
        <NavLink to="/explain">Explain My Platform</NavLink>
      </nav>

      <main className="main-content">
        {lastUpdated ? <p className="muted">Updated {lastUpdated}</p> : null}
        {children}
      </main>
    </div>
  );
}
