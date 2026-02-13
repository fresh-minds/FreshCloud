# FreshCloud Frontend Dashboard

## Work Item Contract
- Inputs: Platform scope from `AGENTS.md`, current repository docs under `/docs`, and existing Argo CD GitOps model.
- Outputs: ARM-friendly frontend dashboard scaffold with architecture map, health overview, docs integration, and GitOps-ready deployment manifests.
- Acceptance Criteria: App renders required pages from mock data without backend dependencies and exposes stubs for Prometheus + Kubernetes API integration.
- How to Verify: Run `npm ci && npm run build`, then `npm run dev` and check overview, architecture, component details, docs rendering, and explain mode.

## Local Run
```bash
cd frontend
cp .env.example .env
npm ci
npm run dev
```

Open [http://localhost:5173](http://localhost:5173).

## Data Modes
- `VITE_DATA_MODE=mock`: Uses bundled mock snapshot (default).
- `VITE_DATA_MODE=hybrid`: Tries live endpoints and falls back to mock.
- `VITE_DATA_MODE=live`: Requires API endpoints; fails when unavailable.

## Build and Container
```bash
cd frontend
npm run build
docker build -t freshcloud-ui:0.1.0 .
```

Container serves static assets on port `8080`.

## GitOps Deployment Path
Use manifests in `frontend/deploy` with Argo CD.

1. Build and push image:
```bash
docker buildx build --platform linux/arm64 -t ghcr.io/<org>/freshcloud-ui:0.1.0 --push frontend
```

2. Set image tag in one of:
- `frontend/deploy/overlays/dev/kustomization.yaml`
- `frontend/deploy/overlays/stage/kustomization.yaml`
- `frontend/deploy/overlays/prod/kustomization.yaml`

3. Apply via Argo CD application manifest:
```bash
kubectl apply -f frontend/deploy/argocd/application-dev.yaml
```

4. Verify rollout:
```bash
kubectl -n freshcloud-ui get pods,svc,ingress
kubectl -n argocd get applications freshcloud-ui-dev
```
