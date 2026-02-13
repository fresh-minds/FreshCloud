import { HealthBadge } from '@/components/common/HealthBadge';
import { formatTimestamp } from '@/lib/format';
import type { SecuritySnapshot } from '@/types/platform';

interface SecurityOverviewCardProps {
  security: SecuritySnapshot;
}

export function SecurityOverviewCard({ security }: SecurityOverviewCardProps): JSX.Element {
  return (
    <section className="panel">
      <h3>Security Overview</h3>
      <dl className="security-grid">
        <div>
          <dt>TLS certificates</dt>
          <dd>
            <HealthBadge status={security.tlsCertificatesStatus} />
          </dd>
        </div>
        <div>
          <dt>RBAC summary</dt>
          <dd>{security.rbacSummary}</dd>
        </div>
        <div>
          <dt>Network policies active</dt>
          <dd>{security.networkPoliciesActive}</dd>
        </div>
        <div>
          <dt>Last backup</dt>
          <dd>{formatTimestamp(security.lastBackupTimestamp)}</dd>
        </div>
      </dl>
    </section>
  );
}
