import type { AlertItem } from '@/types/platform';

interface AlertListProps {
  alerts: AlertItem[];
}

export function AlertList({ alerts }: AlertListProps): JSX.Element {
  if (!alerts.length) {
    return (
      <section className="panel">
        <h3>Alerts</h3>
        <p className="muted">No alerts</p>
      </section>
    );
  }

  return (
    <section className="panel">
      <h3>Alerts</h3>
      <ul className="alert-list">
        {alerts.map((alert) => (
          <li key={alert.id} className={`alert-item severity-${alert.severity}`}>
            <div>
              <p>{alert.message}</p>
              <small>{alert.source}</small>
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}
