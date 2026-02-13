import { useCallback, useEffect, useMemo, useState } from 'react';
import { fetchPlatformSnapshot } from '@/services/platformDataService';
import type { PlatformSnapshot } from '@/types/platform';

interface UsePlatformSnapshotResult {
  data: PlatformSnapshot | null;
  error: string | null;
  loading: boolean;
  refresh: () => Promise<void>;
}

const refreshIntervalMs = 30_000;

export function usePlatformSnapshot(): UsePlatformSnapshotResult {
  const [data, setData] = useState<PlatformSnapshot | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  const load = useCallback(async () => {
    setLoading(true);

    try {
      const snapshot = await fetchPlatformSnapshot();
      setData(snapshot);
      setError(null);
    } catch (requestError) {
      const message = requestError instanceof Error ? requestError.message : 'Unknown data error';
      setError(message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();

    const interval = window.setInterval(() => {
      void load();
    }, refreshIntervalMs);

    return () => {
      window.clearInterval(interval);
    };
  }, [load]);

  return useMemo(
    () => ({
      data,
      error,
      loading,
      refresh: load
    }),
    [data, error, loading, load]
  );
}
