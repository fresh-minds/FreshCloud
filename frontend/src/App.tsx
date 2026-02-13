import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AppLayout } from '@/components/layout/AppLayout';
import { ViewProvider } from '@/context/ViewContext';
import { usePlatformSnapshot } from '@/hooks/usePlatformSnapshot';
import { formatTimestamp } from '@/lib/format';
import { ArchitecturePage } from '@/pages/ArchitecturePage';
import { ComponentDetailPage } from '@/pages/ComponentDetailPage';
import { DocumentationPage } from '@/pages/DocumentationPage';
import { ExplainModePage } from '@/pages/ExplainModePage';
import { OverviewPage } from '@/pages/OverviewPage';

function DashboardRoutes(): JSX.Element {
  const { data, error, loading, refresh } = usePlatformSnapshot();

  if (loading && !data) {
    return (
      <AppLayout>
        <section className="panel">
          <h2>Loading platform snapshot…</h2>
        </section>
      </AppLayout>
    );
  }

  if (!data) {
    return (
      <AppLayout onRefresh={() => void refresh()}>
        <section className="panel">
          <h2>Unable to load data</h2>
          <p className="muted">{error ?? 'No platform snapshot available.'}</p>
        </section>
      </AppLayout>
    );
  }

  return (
    <AppLayout lastUpdated={formatTimestamp(data.generatedAt)} onRefresh={() => void refresh()}>
      {error ? (
        <section className="panel warning-panel">
          <p>{error}</p>
        </section>
      ) : null}

      <Routes>
        <Route path="/" element={<OverviewPage snapshot={data} />} />
        <Route path="/architecture" element={<ArchitecturePage snapshot={data} />} />
        <Route path="/component/:componentId" element={<ComponentDetailPage snapshot={data} />} />
        <Route path="/docs" element={<DocumentationPage />} />
        <Route path="/explain" element={<ExplainModePage snapshot={data} />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AppLayout>
  );
}

export default function App(): JSX.Element {
  return (
    <ViewProvider>
      <BrowserRouter>
        <DashboardRoutes />
      </BrowserRouter>
    </ViewProvider>
  );
}
