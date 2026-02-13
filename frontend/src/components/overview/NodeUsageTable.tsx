import { ProgressBar } from '@/components/common/ProgressBar';
import { HealthBadge } from '@/components/common/HealthBadge';
import type { InfrastructureNode } from '@/types/platform';

interface NodeUsageTableProps {
  nodes: InfrastructureNode[];
  compact?: boolean;
}

export function NodeUsageTable({ nodes, compact = false }: NodeUsageTableProps): JSX.Element {
  return (
    <section className="panel">
      <h3>Infrastructure Nodes</h3>
      <div className="table-scroll">
        <table className="data-table">
          <thead>
            <tr>
              <th>Node</th>
              <th>Status</th>
              <th>CPU</th>
              <th>Memory</th>
              {!compact ? <th>Disk</th> : null}
              <th>Network</th>
            </tr>
          </thead>
          <tbody>
            {nodes.map((node) => (
              <tr key={node.id}>
                <td>{node.name}</td>
                <td>
                  <HealthBadge status={node.status} />
                </td>
                <td>
                  <ProgressBar value={node.usage.cpuPercent} title={`${node.name} CPU`} />
                </td>
                <td>
                  <ProgressBar value={node.usage.memoryPercent} title={`${node.name} memory`} />
                </td>
                {!compact ? (
                  <td>
                    <ProgressBar value={node.usage.diskPercent} title={`${node.name} disk`} />
                  </td>
                ) : null}
                <td>{node.networkStatus}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
