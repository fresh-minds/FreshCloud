import { fetchPlatformSnapshotFromProxy } from '@/api/platformProxy';
import { fetchKubernetesOverview } from '@/api/kubernetes';
import { parsePrometheusValue, queryPrometheusInstant } from '@/api/prometheus';
import { mockPlatformSnapshot } from '@/data/mockData';
import type { AlertItem, HealthStatus, PlatformSnapshot } from '@/types/platform';

const mode = (import.meta.env.VITE_DATA_MODE ?? 'mock') as 'mock' | 'hybrid' | 'live';

function statusFromPercent(value: number): HealthStatus {
  if (value >= 90) {
    return 'critical';
  }

  if (value >= 75) {
    return 'degraded';
  }

  return 'healthy';
}

async function loadLiveSnapshot(): Promise<PlatformSnapshot> {
  try {
    return await fetchPlatformSnapshotFromProxy();
  } catch {
    // Fall back to direct integration stubs when no aggregator API exists.
  }

  const [k8sOverview, cpuResult, memoryResult] = await Promise.all([
    fetchKubernetesOverview(),
    queryPrometheusInstant('avg(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))'),
    queryPrometheusInstant('avg((1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100)')
  ]);

  const cpuAvg = parsePrometheusValue(cpuResult[0]);
  const memoryAvg = parsePrometheusValue(memoryResult[0]);

  const liveSnapshot: PlatformSnapshot = {
    ...mockPlatformSnapshot,
    generatedAt: new Date().toISOString(),
    infrastructureNodes: mockPlatformSnapshot.infrastructureNodes.map((node) => {
      const matched = k8sOverview.nodes.find((n) => n.name === node.name || n.name.includes(node.name));
      if (!matched) {
        return node;
      }

      return {
        ...node,
        status: matched.ready ? statusFromPercent(matched.diskPercent) : 'critical',
        networkStatus: matched.ready ? 'online' : 'offline',
        usage: {
          cpuPercent: matched.cpuPercent,
          memoryPercent: matched.memoryPercent,
          diskPercent: matched.diskPercent
        }
      };
    }),
    kubernetes: {
      clusterHealth: k8sOverview.clusterHealth,
      nodeReadiness: k8sOverview.nodeReadiness,
      controlPlaneStatus: k8sOverview.controlPlaneStatus,
      storageClassHealth: k8sOverview.storageClassHealth,
      ingressStatus: k8sOverview.ingressStatus
    },
    summary: {
      ...mockPlatformSnapshot.summary,
      overallHealth: k8sOverview.clusterHealth,
      alerts: mockPlatformSnapshot.summary.alerts,
      storageUsedPercent:
        cpuAvg === null || memoryAvg === null
          ? mockPlatformSnapshot.summary.storageUsedPercent
          : Math.round((cpuAvg + memoryAvg) / 2)
    }
  };

  return liveSnapshot;
}

function withDataWarning(snapshot: PlatformSnapshot, reason: string): PlatformSnapshot {
  const warning: AlertItem = {
    id: 'data-source-warning',
    severity: 'warning',
    message: `Live data unavailable, showing mock snapshot (${reason}).`,
    source: 'platform-data-service'
  };

  return {
    ...snapshot,
    generatedAt: new Date().toISOString(),
    summary: {
      ...snapshot.summary,
      overallHealth: 'degraded',
      alerts: [warning, ...snapshot.summary.alerts]
    }
  };
}

export async function fetchPlatformSnapshot(): Promise<PlatformSnapshot> {
  if (mode === 'mock') {
    return {
      ...mockPlatformSnapshot,
      generatedAt: new Date().toISOString()
    };
  }

  try {
    return await loadLiveSnapshot();
  } catch (error) {
    if (mode === 'live') {
      throw error;
    }

    const message = error instanceof Error ? error.message : 'unknown error';
    return withDataWarning(mockPlatformSnapshot, message);
  }
}
