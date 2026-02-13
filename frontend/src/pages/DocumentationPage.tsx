import { useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { DocsSidebar } from '@/components/docs/DocsSidebar';
import { MarkdownDocViewer } from '@/components/docs/MarkdownDocViewer';
import { getDocByPath, listDocs } from '@/lib/docs';

const defaultDoc = '/docs/architecture-mvp.md';

export function DocumentationPage(): JSX.Element {
  const docs = useMemo(() => listDocs(), []);
  const [searchParams, setSearchParams] = useSearchParams();

  const selectedPath = searchParams.get('file') ?? defaultDoc;
  const selectedDoc = getDocByPath(selectedPath) ?? docs[0];

  return (
    <div className="docs-grid">
      <DocsSidebar
        docs={docs}
        selectedPath={selectedDoc.path}
        onSelect={(path) => setSearchParams({ file: path })}
      />
      <MarkdownDocViewer doc={selectedDoc} />
    </div>
  );
}
