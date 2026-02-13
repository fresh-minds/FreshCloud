import { Link } from 'react-router-dom';
import { HealthBadge } from '@/components/common/HealthBadge';
import type { ComponentDetail, LayerSummary } from '@/types/platform';

interface LayerDetailsPanelProps {
  layer: LayerSummary;
  components: ComponentDetail[];
}

export function LayerDetailsPanel({ layer, components }: LayerDetailsPanelProps): JSX.Element {
  return (
    <section className="panel">
      <div className="panel-heading">
        <h3>{layer.label}</h3>
        <HealthBadge status={layer.status} />
      </div>
      <p className="muted">{layer.shortDescription}</p>
      <ul className="component-list">
        {components.map((component) => (
          <li key={component.id}>
            <div>
              <p>{component.name}</p>
              <small className="muted">{component.description}</small>
            </div>
            <div className="service-actions">
              <Link className="inline-link" to={`/component/${component.id}`}>
                Inspect
              </Link>
              <Link
                className="inline-link"
                to={{
                  pathname: '/docs',
                  search: `?file=${encodeURIComponent(component.docsPath)}`
                }}
              >
                Docs
              </Link>
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}
