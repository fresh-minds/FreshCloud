export interface DocEntry {
  path: string;
  title: string;
  markdown: string;
}

const docsModules = import.meta.glob('../../../docs/**/*.md', {
  query: '?raw',
  import: 'default',
  eager: true
}) as Record<string, string>;

function normalizePath(modulePath: string): string {
  return modulePath
    .replace(/^\.\.\/\.\.\/\.\.\//, '/')
    .replace(/\/+/g, '/');
}

function extractTitle(markdown: string, fallback: string): string {
  const header = markdown
    .split('\n')
    .map((line) => line.trim())
    .find((line) => line.startsWith('# '));

  if (!header) {
    return fallback;
  }

  return header.replace(/^#\s+/, '').trim();
}

const docEntries: DocEntry[] = Object.entries(docsModules)
  .map(([modulePath, markdown]) => {
    const path = normalizePath(modulePath);
    const fallback = path.split('/').pop()?.replace('.md', '') ?? 'Document';

    return {
      path,
      title: extractTitle(markdown, fallback),
      markdown
    };
  })
  .sort((a, b) => a.title.localeCompare(b.title));

export function listDocs(): DocEntry[] {
  return docEntries;
}

export function getDocByPath(path: string): DocEntry | undefined {
  return docEntries.find((entry) => entry.path === path);
}
