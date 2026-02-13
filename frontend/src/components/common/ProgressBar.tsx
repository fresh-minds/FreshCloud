interface ProgressBarProps {
  value: number;
  title?: string;
}

export function ProgressBar({ value, title }: ProgressBarProps): JSX.Element {
  const normalized = Math.max(0, Math.min(100, Math.round(value)));

  return (
    <div className="progress-wrap" aria-label={title} title={title}>
      <div className="progress-fill" style={{ width: `${normalized}%` }} />
      <span className="progress-value">{normalized}%</span>
    </div>
  );
}
