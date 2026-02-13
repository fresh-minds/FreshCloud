import { StatCard } from '@/components/common/StatCard';
import { AlertList } from '@/components/overview/AlertList';
import { LayerStatusCards } from '@/components/overview/LayerStatusCards';
import { NodeUsageTable } from '@/components/overview/NodeUsageTable';
import { PlatformServiceList } from '@/components/overview/PlatformServiceList';
import { WorkloadTable } from '@/components/overview/WorkloadTable';
import { SecurityOverviewCard } from '@/components/security/SecurityOverviewCard';
import { useViewContext } from '@/context/ViewContext';
import { healthLabel } from '@/lib/format';
import type { PlatformSnapshot } from '@/types/platform';

interface OverviewPageProps {
  snapshot: PlatformSnapshot;
}

export function OverviewPage({ snapshot }: OverviewPageProps): JSX.Element {
  const { explainMode, role } = useViewContext();

  return (
    <div className="page-grid">
      <section className="stats-grid">
        <StatCard label="Overall health" value={healthLabel(snapshot.summary.overallHealth)} />
        <StatCard label="Total nodes" value={snapshot.summary.totalNodes} />
        <StatCard label="Total workloads" value={snapshot.summary.totalWorkloads} />
        <StatCard label="Storage used" value={`${snapshot.summary.storageUsedPercent}%`} />
      </section>

      <LayerStatusCards layers={snapshot.architectureLayers} />
      <AlertList alerts={snapshot.summary.alerts} />

      <NodeUsageTable
        nodes={snapshot.infrastructureNodes}
        compact={explainMode || role === 'viewer'}
      />

      {!explainMode ? <PlatformServiceList services={snapshot.platformServices} /> : null}
      <WorkloadTable namespaces={snapshot.workloads} />
      <SecurityOverviewCard security={snapshot.security} />

      {role === 'viewer' ? (
        <section className="panel">
          <h3>Viewer Mode</h3>
          <p className="muted">
            Raw troubleshooting values are hidden. Switch to Operator mode for deeper metrics.
          </p>
        </section>
      ) : null}
    </div>
  );
}
