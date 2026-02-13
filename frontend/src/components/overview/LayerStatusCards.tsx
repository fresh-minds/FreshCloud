import { Link } from 'react-router-dom';
import { HealthBadge } from '@/components/common/HealthBadge';
import type { LayerSummary } from '@/types/platform';

interface LayerStatusCardsProps {
  layers: LayerSummary[];
}

export function LayerStatusCards({ layers }: LayerStatusCardsProps): JSX.Element {
  return (
    <section className="panel">
      <div className="panel-heading">
        <h3>Layer Health</h3>
        <Link to="/architecture" className="inline-link">
          Open architecture map
        </Link>
      </div>
      <div className="layer-card-grid">
        {layers.map((layer) => (
          <article key={layer.id} className="layer-card">
            <div className="layer-card-top">
              <p>{layer.label}</p>
              <HealthBadge status={layer.status} />
            </div>
            <p className="muted">{layer.shortDescription}</p>
          </article>
        ))}
      </div>
    </section>
  );
}
