import type { WorkloadNamespace } from '@/types/platform';

interface WorkloadTableProps {
  namespaces: WorkloadNamespace[];
}

export function WorkloadTable({ namespaces }: WorkloadTableProps): JSX.Element {
  return (
    <section className="panel">
      <h3>Workloads</h3>
      <div className="table-scroll">
        <table className="data-table">
          <thead>
            <tr>
              <th>Namespace</th>
              <th>Apps</th>
              <th>Pods</th>
              <th>Deployments</th>
            </tr>
          </thead>
          <tbody>
            {namespaces.map((namespace) => (
              <tr key={namespace.name}>
                <td>{namespace.name}</td>
                <td>{namespace.apps}</td>
                <td>{namespace.pods}</td>
                <td>
                  {namespace.healthyDeployments}/{namespace.totalDeployments}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
