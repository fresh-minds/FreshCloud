import type { HealthStatus } from '@/types/platform';
import { healthLabel } from '@/lib/format';

interface HealthBadgeProps {
  status: HealthStatus;
}

export function HealthBadge({ status }: HealthBadgeProps): JSX.Element {
  return <span className={`health-badge health-${status}`}>{healthLabel(status)}</span>;
}
