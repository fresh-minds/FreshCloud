# FreshCloud UX Architecture

## Work Item Contract
- Inputs: `AGENTS.md` non-negotiables, existing architecture/docs in `/docs`, and current Argo CD GitOps standard in `docs/gitops.md`.
- Outputs: Lightweight frontend dashboard in `/frontend`, architecture map + detail pages, markdown documentation integration, and GitOps deployment manifests.
- Acceptance Criteria: Operator can open one URL and understand infrastructure, Kubernetes, platform services, workloads, and security posture in under 60 seconds.
- How to Verify: Build and run frontend (`npm ci && npm run build && npm run dev`), check all required pages/features, then validate Kubernetes manifests with `kubectl kustomize frontend/deploy/overlays/dev`.

## Goal and Constraints
This UI is intentionally not a generic admin panel. It combines:
- Architecture visualization
- Living platform documentation
- Operational health overview
- Explainable platform narrative for colleagues

Hard constraints:
- Dark-mode-first, minimal card-based UX
- ARM-friendly, small static container
- No heavy backend dependency
- Works with GitOps and Kubernetes conventions already in this repo

## Tech Stack Decision
Chosen stack: **Vite + React + TypeScript**.

Why this stack (and not Next.js/Vue/Alpine):
- Lowest runtime overhead: static assets served by NGINX, no Node SSR process.
- Fast startup and small memory profile on ARM.
- React component model fits layered architecture UI and clickable detail panels.
- Easy markdown rendering and routing without introducing backend complexity.
- Clean integration path to Prometheus + Kubernetes APIs via small proxy endpoints.

## UI Architecture
### Runtime Modes
- Role mode:
  - `viewer`: read-only presentation mode with reduced raw troubleshooting data.
  - `operator`: full detail mode for diagnostics and runbook navigation.
- Explain mode:
  - Focus on architecture + intent.
  - Hides noisy operational metrics for colleague walkthroughs.

### Data Flow
```text
Prometheus API ----\
                    \         /-> Overview cards + health badges
Kubernetes API -----> API Stub/Proxy -> PlatformSnapshot model -> Architecture map
                    /         \-> Component detail + docs links
Repository /docs --/
```

Data source strategy:
- Default `mock` mode (no backend dependency).
- `hybrid` mode: tries live endpoints, falls back to mock.
- `live` mode: requires API endpoints.

### Component Map Diagram (Text)
```text
┌─────────────────────────────────────────────────────────────────┐
│ Workloads                                                      │
│ Namespaces, apps, deployment health, pod counts               │
├─────────────────────────────────────────────────────────────────┤
│ Platform Services                                              │
│ Argo CD, Postgres, MinIO, Observability, Secrets, Backups     │
├─────────────────────────────────────────────────────────────────┤
│ Kubernetes Cluster                                             │
│ Node readiness, control plane, storage classes, ingress        │
├─────────────────────────────────────────────────────────────────┤
│ Raspberry Pi Nodes                                             │
│ Pi1-Pi4 CPU/memory/disk/network                               │
└─────────────────────────────────────────────────────────────────┘
```

## Frontend Structure
```text
frontend/
├── src/
│   ├── api/
│   │   ├── kubernetes.ts
│   │   ├── platformProxy.ts
│   │   └── prometheus.ts
│   ├── components/
│   │   ├── architecture/
│   │   ├── common/
│   │   ├── docs/
│   │   ├── layout/
│   │   ├── overview/
│   │   └── security/
│   ├── context/ViewContext.tsx
│   ├── data/mockData.ts
│   ├── hooks/usePlatformSnapshot.ts
│   ├── lib/{docs.ts,format.ts}
│   ├── pages/
│   │   ├── OverviewPage.tsx
│   │   ├── ArchitecturePage.tsx
│   │   ├── ComponentDetailPage.tsx
│   │   ├── DocumentationPage.tsx
│   │   └── ExplainModePage.tsx
│   ├── services/platformDataService.ts
│   ├── types/platform.ts
│   ├── App.tsx
│   └── main.tsx
├── deploy/
│   ├── argocd/
│   ├── base/
│   └── overlays/{dev,stage,prod}
├── Dockerfile
├── nginx.conf
└── README.md
```

## Page and Feature Coverage
### 1) Dashboard Overview Page
- Overall health summary with severity coloring.
- Total nodes/workloads/storage used.
- Alerts panel.
- Node usage table and service/workload/security cards.

### 2) Architecture Page
- Layered clickable stack view.
- Detail panel per selected layer.
- Direct links to component details and docs.

### 3) Component Detail Page
- Description + purpose.
- Dependencies.
- Health indicators.
- Runbook and docs links.

### 4) Documentation Integration
- Auto-load markdown from repository `/docs` at build time.
- Inline render via markdown viewer.
- Component cards deep-link to docs path.

### 5) Explain My Platform Mode
- Presentation view focused on structure and purpose.
- Reduced metric noise for stakeholder demos.

### 6) Minimal Role Awareness
- Viewer mode and Operator mode in top bar.
- Viewer mode suppresses some raw operational details.

## Lightweight and ARM Considerations
- No SSR process; static bundle served by NGINX.
- No heavy charting library.
- Card/grid + progress bars built in CSS.
- Container requests/limits set conservatively:
  - Request: `40Mi`
  - Limit: `120Mi`
- Target: remain comfortably under 200MB pod memory envelope.

## GitOps Deployment (Argo CD)
### Build and publish
```bash
docker buildx build --platform linux/arm64 \
  -t ghcr.io/<org>/freshcloud-ui:0.1.0 \
  --push frontend
```

### Update overlay image tag
Edit one of:
- `frontend/deploy/overlays/dev/kustomization.yaml`
- `frontend/deploy/overlays/stage/kustomization.yaml`
- `frontend/deploy/overlays/prod/kustomization.yaml`

### Deploy via Argo CD application
```bash
kubectl apply -f frontend/deploy/argocd/application-dev.yaml
```

### Verify
```bash
kubectl -n argocd get applications freshcloud-ui-dev
kubectl -n freshcloud-ui get deploy,pods,svc,ingress
kubectl -n freshcloud-ui describe ingress freshcloud-ui
```

Expected:
- Argo app becomes `Synced` and `Healthy`.
- UI pod is `Running` and ingress host resolves.
- Dashboard loads and renders architecture/docs pages.

## Assumptions and To Verify
- [ ] Ingress hostnames (`ui-dev.freshcloud.local`, etc.) are managed in DNS.
- [ ] Cluster has ingress-nginx + cert-manager already healthy.
- [ ] Private access policy for Prometheus/API endpoints is defined.
- [ ] Final live data proxy endpoint contract is agreed (`/api/platform/snapshot`).
- [ ] ARM64 image registry and pull credentials are configured in cluster.

## Component Hierarchy
```text
App
└── ViewProvider
    └── BrowserRouter
        └── AppLayout
            ├── Topbar (role + explain controls)
            ├── Primary nav
            └── Routes
                ├── OverviewPage
                ├── ArchitecturePage
                ├── ComponentDetailPage
                ├── DocumentationPage
                └── ExplainModePage
```

## Sample Layout Description
- Top bar: identity, role mode, explain toggle, refresh.
- Primary nav: Overview, Architecture, Documentation, Explain.
- Main content: responsive card grid.
- Visual identity: deep navy background, muted neutrals, FreshCloud blue accent, compact health badges.
- Interaction style: click-focused and fast, with no unnecessary animation.
