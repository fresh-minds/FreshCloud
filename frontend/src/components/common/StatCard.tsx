import type { ReactNode } from 'react';

interface StatCardProps {
  label: string;
  value: string | number;
  note?: string;
  children?: ReactNode;
}

export function StatCard({ label, value, note, children }: StatCardProps): JSX.Element {
  return (
    <section className="panel stat-card">
      <p className="label">{label}</p>
      <p className="value">{value}</p>
      {note ? <p className="note">{note}</p> : null}
      {children}
    </section>
  );
}
