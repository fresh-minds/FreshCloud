import { Link } from 'react-router-dom';
import { HealthBadge } from '@/components/common/HealthBadge';
import type { PlatformService } from '@/types/platform';

interface PlatformServiceListProps {
  services: PlatformService[];
}

export function PlatformServiceList({ services }: PlatformServiceListProps): JSX.Element {
  return (
    <section className="panel">
      <h3>Platform Services</h3>
      <ul className="service-list">
        {services.map((service) => (
          <li key={service.id}>
            <div>
              <p>{service.name}</p>
              <small className="muted">
                Replicas {service.readyReplicas}/{service.replicas}
                {typeof service.latencyMs === 'number' ? ` • ${service.latencyMs}ms` : ''}
              </small>
            </div>
            <div className="service-actions">
              <HealthBadge status={service.status} />
              <Link to={`/component/${service.id}`} className="inline-link">
                Details
              </Link>
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}
