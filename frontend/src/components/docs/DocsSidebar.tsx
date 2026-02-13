import type { DocEntry } from '@/lib/docs';

interface DocsSidebarProps {
  docs: DocEntry[];
  selectedPath: string;
  onSelect: (path: string) => void;
}

export function DocsSidebar({ docs, selectedPath, onSelect }: DocsSidebarProps): JSX.Element {
  return (
    <aside className="panel docs-sidebar">
      <h3>Repository Docs</h3>
      <ul className="docs-list">
        {docs.map((doc) => (
          <li key={doc.path}>
            <button
              type="button"
              className={doc.path === selectedPath ? 'active' : ''}
              onClick={() => onSelect(doc.path)}
            >
              {doc.title}
            </button>
          </li>
        ))}
      </ul>
    </aside>
  );
}
