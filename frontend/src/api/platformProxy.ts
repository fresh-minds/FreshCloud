import type { PlatformSnapshot } from '@/types/platform';

const defaultApiBase = import.meta.env.VITE_PLATFORM_API_BASE ?? '';

export async function fetchPlatformSnapshotFromProxy(
  baseUrl = defaultApiBase
): Promise<PlatformSnapshot> {
  const endpoint = `${baseUrl}/api/platform/snapshot`;
  const response = await fetch(endpoint, {
    headers: {
      Accept: 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error(`Platform snapshot proxy request failed: ${response.status}`);
  }

  return (await response.json()) as PlatformSnapshot;
}
