import { useMemo, useState } from 'react';
import { ArchitectureStack } from '@/components/architecture/ArchitectureStack';
import { LayerDetailsPanel } from '@/components/architecture/LayerDetailsPanel';
import type { LayerId, PlatformSnapshot } from '@/types/platform';

interface ArchitecturePageProps {
  snapshot: PlatformSnapshot;
}

export function ArchitecturePage({ snapshot }: ArchitecturePageProps): JSX.Element {
  const [selectedLayer, setSelectedLayer] = useState<LayerId>('workloads');

  const currentLayer =
    snapshot.architectureLayers.find((layer) => layer.id === selectedLayer) ??
    snapshot.architectureLayers[0];

  const layerComponents = useMemo(
    () => snapshot.components.filter((component) => component.layer === currentLayer.id),
    [snapshot.components, currentLayer.id]
  );

  return (
    <div className="split-grid">
      <ArchitectureStack
        layers={snapshot.architectureLayers}
        selected={currentLayer.id}
        onSelect={(layerId) => setSelectedLayer(layerId as LayerId)}
      />
      <LayerDetailsPanel layer={currentLayer} components={layerComponents} />
    </div>
  );
}
