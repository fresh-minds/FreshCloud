import { Link } from 'react-router-dom';
import { HealthBadge } from '@/components/common/HealthBadge';
import type { PlatformSnapshot } from '@/types/platform';

interface ExplainModePageProps {
  snapshot: PlatformSnapshot;
}

export function ExplainModePage({ snapshot }: ExplainModePageProps): JSX.Element {
  return (
    <div className="page-grid">
      <section className="panel">
        <h2>Explain My Platform</h2>
        <p className="muted">
          FreshCloud runs in layered form: physical nodes, Kubernetes core, shared platform services and
          application workloads.
        </p>
      </section>

      <section className="panel architecture-panel">
        <h3>Layered stack</h3>
        <div className="architecture-stack explain-stack">
          {snapshot.architectureLayers.map((layer) => (
            <div className="layer-block static" key={layer.id}>
              <div>
                <strong>{layer.label}</strong>
                <p className="muted">{layer.shortDescription}</p>
              </div>
              <HealthBadge status={layer.status} />
            </div>
          ))}
        </div>
      </section>

      <section className="panel">
        <h3>Core services in this platform</h3>
        <ul className="simple-list">
          {snapshot.platformServices.map((service) => (
            <li key={service.id}>
              {service.name} <HealthBadge status={service.status} />
            </li>
          ))}
        </ul>
      </section>

      <section className="panel">
        <h3>Learn more</h3>
        <p className="muted">Use documentation mode to read architecture, runbooks and operating standards.</p>
        <Link className="inline-link" to="/docs?file=%2Fdocs%2Frunbooks.md">
          Open runbooks
        </Link>
      </section>
    </div>
  );
}
