export type HealthStatus = 'healthy' | 'degraded' | 'critical' | 'unknown';

export type RoleMode = 'viewer' | 'operator';

export type LayerId =
  | 'infrastructure'
  | 'kubernetes'
  | 'platform-services'
  | 'workloads'
  | 'security';

export interface AlertItem {
  id: string;
  severity: 'info' | 'warning' | 'critical';
  message: string;
  source: string;
}

export interface ResourceUsage {
  cpuPercent: number;
  memoryPercent: number;
  diskPercent: number;
}

export interface InfrastructureNode {
  id: string;
  name: string;
  role: 'control-plane' | 'worker' | 'hybrid';
  status: HealthStatus;
  networkStatus: 'online' | 'degraded' | 'offline';
  usage: ResourceUsage;
}

export interface LayerSummary {
  id: LayerId;
  label: string;
  status: HealthStatus;
  shortDescription: string;
}

export interface PlatformService {
  id: string;
  name: string;
  status: HealthStatus;
  latencyMs?: number;
  replicas: number;
  readyReplicas: number;
  description: string;
  docsPath: string;
  dependencies: string[];
}

export interface WorkloadNamespace {
  name: string;
  apps: number;
  pods: number;
  healthyDeployments: number;
  totalDeployments: number;
}

export interface SecuritySnapshot {
  tlsCertificatesStatus: HealthStatus;
  rbacSummary: string;
  networkPoliciesActive: number;
  lastBackupTimestamp: string;
}

export interface KubernetesSnapshot {
  clusterHealth: HealthStatus;
  nodeReadiness: string;
  controlPlaneStatus: HealthStatus;
  storageClassHealth: HealthStatus;
  ingressStatus: HealthStatus;
}

export interface PlatformSummary {
  overallHealth: HealthStatus;
  totalNodes: number;
  totalWorkloads: number;
  storageUsedPercent: number;
  alerts: AlertItem[];
}

export interface ComponentDetail {
  id: string;
  name: string;
  layer: LayerId;
  status: HealthStatus;
  description: string;
  whatItDoes: string;
  dependencies: string[];
  indicators: string[];
  docsPath: string;
  runbookPath: string;
}

export interface PlatformSnapshot {
  generatedAt: string;
  summary: PlatformSummary;
  architectureLayers: LayerSummary[];
  infrastructureNodes: InfrastructureNode[];
  kubernetes: KubernetesSnapshot;
  platformServices: PlatformService[];
  workloads: WorkloadNamespace[];
  security: SecuritySnapshot;
  components: ComponentDetail[];
}
