import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import type { DocEntry } from '@/lib/docs';

interface MarkdownDocViewerProps {
  doc: DocEntry;
}

export function MarkdownDocViewer({ doc }: MarkdownDocViewerProps): JSX.Element {
  return (
    <section className="panel markdown-viewer">
      <div className="panel-heading">
        <h3>{doc.title}</h3>
        <small className="muted mono">{doc.path}</small>
      </div>
      <article className="markdown-body">
        <ReactMarkdown remarkPlugins={[remarkGfm]}>{doc.markdown}</ReactMarkdown>
      </article>
    </section>
  );
}
