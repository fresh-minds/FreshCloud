export interface KubernetesNodeInfo {
  name: string;
  ready: boolean;
  cpuPercent: number;
  memoryPercent: number;
  diskPercent: number;
}

export interface KubernetesOverviewResponse {
  clusterHealth: 'healthy' | 'degraded' | 'critical' | 'unknown';
  nodeReadiness: string;
  controlPlaneStatus: 'healthy' | 'degraded' | 'critical' | 'unknown';
  storageClassHealth: 'healthy' | 'degraded' | 'critical' | 'unknown';
  ingressStatus: 'healthy' | 'degraded' | 'critical' | 'unknown';
  nodes: KubernetesNodeInfo[];
}

const defaultApiBase = import.meta.env.VITE_PLATFORM_API_BASE ?? '';

export async function fetchKubernetesOverview(
  baseUrl = defaultApiBase
): Promise<KubernetesOverviewResponse> {
  const endpoint = `${baseUrl}/api/platform/kubernetes-overview`;
  const response = await fetch(endpoint, {
    headers: {
      Accept: 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error(`Kubernetes overview request failed: ${response.status}`);
  }

  return (await response.json()) as KubernetesOverviewResponse;
}
