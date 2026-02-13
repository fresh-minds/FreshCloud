import { HealthBadge } from '@/components/common/HealthBadge';
import type { LayerSummary } from '@/types/platform';

interface ArchitectureStackProps {
  layers: LayerSummary[];
  selected: string;
  onSelect: (layerId: string) => void;
}

export function ArchitectureStack({ layers, selected, onSelect }: ArchitectureStackProps): JSX.Element {
  return (
    <section className="panel architecture-panel">
      <h3>Architecture Map</h3>
      <div className="architecture-stack" role="list" aria-label="FreshCloud architecture layers">
        {layers.map((layer) => (
          <button
            key={layer.id}
            type="button"
            role="listitem"
            className={`layer-block ${selected === layer.id ? 'active' : ''}`}
            onClick={() => onSelect(layer.id)}
          >
            <div>
              <strong>{layer.label}</strong>
              <p className="muted">{layer.shortDescription}</p>
            </div>
            <HealthBadge status={layer.status} />
          </button>
        ))}
      </div>
    </section>
  );
}
