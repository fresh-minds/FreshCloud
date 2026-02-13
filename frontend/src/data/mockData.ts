import type { PlatformSnapshot } from '@/types/platform';

export const mockPlatformSnapshot: PlatformSnapshot = {
  generatedAt: '2026-02-12T10:45:00Z',
  summary: {
    overallHealth: 'healthy',
    totalNodes: 4,
    totalWorkloads: 23,
    storageUsedPercent: 61,
    alerts: [
      {
        id: 'cert-expiry',
        severity: 'warning',
        message: 'One staging TLS certificate expires in 5 days',
        source: 'cert-manager'
      },
      {
        id: 'backup-lag',
        severity: 'info',
        message: 'Last MinIO backup completed 4h ago',
        source: 'backup-cronjob'
      }
    ]
  },
  architectureLayers: [
    {
      id: 'workloads',
      label: 'Workloads',
      status: 'healthy',
      shortDescription: 'Namespace-scoped applications and deployments.'
    },
    {
      id: 'platform-services',
      label: 'Platform Services',
      status: 'healthy',
      shortDescription: 'GitOps, data services, observability and secret flows.'
    },
    {
      id: 'kubernetes',
      label: 'Kubernetes Cluster',
      status: 'healthy',
      shortDescription: 'RKE2 control plane and service primitives.'
    },
    {
      id: 'infrastructure',
      label: 'Raspberry Pi Nodes',
      status: 'degraded',
      shortDescription: 'ARM nodes with local disks and private networking.'
    },
    {
      id: 'security',
      label: 'Security Guardrails',
      status: 'healthy',
      shortDescription: 'TLS, RBAC, policies and backup confidence.'
    }
  ],
  infrastructureNodes: [
    {
      id: 'pi-1',
      name: 'Pi1',
      role: 'hybrid',
      status: 'healthy',
      networkStatus: 'online',
      usage: {
        cpuPercent: 32,
        memoryPercent: 58,
        diskPercent: 51
      }
    },
    {
      id: 'pi-2',
      name: 'Pi2',
      role: 'hybrid',
      status: 'healthy',
      networkStatus: 'online',
      usage: {
        cpuPercent: 47,
        memoryPercent: 61,
        diskPercent: 56
      }
    },
    {
      id: 'pi-3',
      name: 'Pi3',
      role: 'hybrid',
      status: 'degraded',
      networkStatus: 'degraded',
      usage: {
        cpuPercent: 72,
        memoryPercent: 75,
        diskPercent: 83
      }
    },
    {
      id: 'pi-4',
      name: 'Pi4',
      role: 'worker',
      status: 'healthy',
      networkStatus: 'online',
      usage: {
        cpuPercent: 38,
        memoryPercent: 49,
        diskPercent: 58
      }
    }
  ],
  kubernetes: {
    clusterHealth: 'healthy',
    nodeReadiness: '4/4 Ready',
    controlPlaneStatus: 'healthy',
    storageClassHealth: 'healthy',
    ingressStatus: 'healthy'
  },
  platformServices: [
    {
      id: 'argocd',
      name: 'GitOps Controller (Argo CD)',
      status: 'healthy',
      latencyMs: 74,
      replicas: 2,
      readyReplicas: 2,
      description: 'Manages sync and desired state from Git repositories.',
      docsPath: '/docs/gitops.md',
      dependencies: ['kubernetes-api', 'git-provider']
    },
    {
      id: 'postgres',
      name: 'Postgres (CloudNativePG)',
      status: 'healthy',
      latencyMs: 12,
      replicas: 2,
      readyReplicas: 2,
      description: 'Primary relational data service with WAL-based backups.',
      docsPath: '/docs/data-services.md',
      dependencies: ['longhorn', 'backup-storage']
    },
    {
      id: 'minio',
      name: 'MinIO',
      status: 'healthy',
      latencyMs: 19,
      replicas: 4,
      readyReplicas: 4,
      description: 'S3-compatible object storage for platform and app backups.',
      docsPath: '/docs/data-services.md',
      dependencies: ['longhorn', 'network-policy']
    },
    {
      id: 'observability',
      name: 'Observability Stack',
      status: 'healthy',
      latencyMs: 88,
      replicas: 3,
      readyReplicas: 3,
      description: 'Prometheus, Loki and dashboards for platform insight.',
      docsPath: '/docs/observability.md',
      dependencies: ['kube-state-metrics', 'node-exporter']
    },
    {
      id: 'external-secrets',
      name: 'Secrets Manager (External Secrets)',
      status: 'healthy',
      latencyMs: 35,
      replicas: 2,
      readyReplicas: 2,
      description: 'Injects secrets into namespaces without plaintext in Git.',
      docsPath: '/docs/security-baseline.md',
      dependencies: ['secret-backend', 'sops']
    },
    {
      id: 'backups',
      name: 'Backup Jobs',
      status: 'degraded',
      latencyMs: 140,
      replicas: 1,
      readyReplicas: 1,
      description: 'Scheduled backup and restore probes for critical state.',
      docsPath: '/docs/runbooks.md',
      dependencies: ['postgres', 'minio']
    }
  ],
  workloads: [
    {
      name: 'dev',
      apps: 7,
      pods: 42,
      healthyDeployments: 12,
      totalDeployments: 12
    },
    {
      name: 'stage',
      apps: 6,
      pods: 28,
      healthyDeployments: 9,
      totalDeployments: 10
    },
    {
      name: 'prod',
      apps: 10,
      pods: 51,
      healthyDeployments: 14,
      totalDeployments: 14
    }
  ],
  security: {
    tlsCertificatesStatus: 'degraded',
    rbacSummary: '42 roles bound, no cluster-admin grants to app namespaces',
    networkPoliciesActive: 27,
    lastBackupTimestamp: '2026-02-12T06:39:00Z'
  },
  components: [
    {
      id: 'component-infra-nodes',
      name: 'Raspberry Pi Node Fleet',
      layer: 'infrastructure',
      status: 'degraded',
      description: 'Four ARM64 nodes powering the cluster.',
      whatItDoes: 'Hosts control-plane and workload processes with local storage and private networking.',
      dependencies: ['power', 'lan-switch', 'rke2-agent'],
      indicators: ['CPU usage', 'Memory pressure', 'Disk pressure', 'Node network health'],
      docsPath: '/docs/cluster-bootstrap.md',
      runbookPath: '/docs/runbooks.md'
    },
    {
      id: 'component-k8s-core',
      name: 'Kubernetes Core',
      layer: 'kubernetes',
      status: 'healthy',
      description: 'RKE2 control plane and scheduling runtime.',
      whatItDoes: 'Provides API server, scheduling, networking and storage abstractions.',
      dependencies: ['etcd quorum', 'cni plugin', 'ingress controller'],
      indicators: ['Node readiness', 'API health', 'StorageClass health', 'Ingress readiness'],
      docsPath: '/docs/architecture-mvp.md',
      runbookPath: '/docs/cluster-bootstrap.md'
    },
    {
      id: 'component-platform-services',
      name: 'Platform Services',
      layer: 'platform-services',
      status: 'healthy',
      description: 'GitOps, databases, object storage, observability and secrets.',
      whatItDoes: 'Runs shared services consumed by every environment and workload.',
      dependencies: ['kubernetes core', 'storage classes', 'network policies'],
      indicators: ['Service replica readiness', 'Backup job success', 'Prometheus target health'],
      docsPath: '/docs/data-services.md',
      runbookPath: '/docs/runbooks.md'
    },
    {
      id: 'component-workloads',
      name: 'Application Workloads',
      layer: 'workloads',
      status: 'healthy',
      description: 'Tenant or product workloads deployed per namespace.',
      whatItDoes: 'Runs your apps while inheriting platform controls and observability.',
      dependencies: ['platform services', 'ingress', 'secrets manager'],
      indicators: ['Deployment availability', 'Pod count', 'Namespace health'],
      docsPath: '/docs/wbs.md',
      runbookPath: '/docs/runbooks.md'
    },
    {
      id: 'component-security',
      name: 'Security Guardrails',
      layer: 'security',
      status: 'healthy',
      description: 'TLS, RBAC and network-policy coverage.',
      whatItDoes: 'Enforces least privilege and encrypted traffic with auditable control points.',
      dependencies: ['cert-manager', 'external-secrets', 'kubernetes admission controls'],
      indicators: ['Certificate expiry window', 'RBAC drift', 'Policy enforcement count'],
      docsPath: '/docs/security-baseline.md',
      runbookPath: '/docs/threat-model.md'
    }
  ]
};
