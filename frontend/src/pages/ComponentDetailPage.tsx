import { Link, useParams } from 'react-router-dom';
import { HealthBadge } from '@/components/common/HealthBadge';
import type { ComponentDetail, PlatformService, PlatformSnapshot } from '@/types/platform';

interface ComponentDetailPageProps {
  snapshot: PlatformSnapshot;
}

function serviceToComponent(service: PlatformService): ComponentDetail {
  return {
    id: service.id,
    name: service.name,
    layer: 'platform-services',
    status: service.status,
    description: service.description,
    whatItDoes: service.description,
    dependencies: service.dependencies,
    indicators: ['Replica readiness', 'Latency', 'Availability'],
    docsPath: service.docsPath,
    runbookPath: '/docs/runbooks.md'
  };
}

export function ComponentDetailPage({ snapshot }: ComponentDetailPageProps): JSX.Element {
  const { componentId } = useParams();

  const componentFromCatalog = snapshot.components.find((entry) => entry.id === componentId);
  const serviceMatch = snapshot.platformServices.find((service) => service.id === componentId);
  const component = componentFromCatalog ?? (serviceMatch ? serviceToComponent(serviceMatch) : null);

  if (!component) {
    return (
      <section className="panel">
        <h2>Component not found</h2>
        <p className="muted">The selected component does not exist in the current snapshot.</p>
      </section>
    );
  }

  return (
    <div className="page-grid">
      <section className="panel">
        <div className="panel-heading">
          <h2>{component.name}</h2>
          <HealthBadge status={component.status} />
        </div>
        <p>{component.description}</p>
      </section>

      <section className="panel">
        <h3>What it does</h3>
        <p>{component.whatItDoes}</p>
      </section>

      <section className="panel">
        <h3>Dependencies</h3>
        <ul className="simple-list">
          {component.dependencies.map((dependency) => (
            <li key={dependency}>{dependency}</li>
          ))}
        </ul>
      </section>

      <section className="panel">
        <h3>Health indicators</h3>
        <ul className="simple-list">
          {component.indicators.map((indicator) => (
            <li key={indicator}>{indicator}</li>
          ))}
        </ul>
      </section>

      <section className="panel">
        <h3>Runbook and docs</h3>
        <div className="link-row">
          <Link
            className="inline-link"
            to={{ pathname: '/docs', search: `?file=${encodeURIComponent(component.docsPath)}` }}
          >
            Open component documentation
          </Link>
          <Link
            className="inline-link"
            to={{ pathname: '/docs', search: `?file=${encodeURIComponent(component.runbookPath)}` }}
          >
            Open runbook
          </Link>
        </div>
      </section>
    </div>
  );
}
