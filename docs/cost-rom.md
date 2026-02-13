# FreshCloud Leaseweb Cost ROM (MVP + 10x Scale Plan)

## Work Item Contract
- Inputs: `docs/architecture-mvp.md`, Leaseweb public pricing pages, MVP scope from `AGENTS.md`.
- Outputs: Monthly cost ROM with 3 sizing options, key cost drivers, 10x usage changes, pricing skeleton, break-even story, and scale triggers.
- Acceptance Criteria: Every cost line maps to explicit resource assumptions and unit prices; includes a break-even explanation and operational trigger points.
- How to Verify: Recalculate totals from the formulas below, then compare to real monthly invoice + Prometheus/Loki usage metrics.

## Pricing Inputs and Assumptions (Explicit)
All numbers below are ROM estimates (ex VAT), captured on **2026-02-12**.

| Item | Unit Price Used | Source/Note |
|---|---:|---|
| Compute node `LSW.R3.XLARGE` (4 vCPU / 30.5 GiB) | EUR 72.57 per node-month | Leaseweb Public Cloud instance pricing. |
| Compute node `LSW.R3.2XLARGE` (8 vCPU / 61 GiB) | EUR 144.74 per node-month | Leaseweb Public Cloud instance pricing. |
| Primary block storage (Network SSD) | EUR 0.08 per GB-month (EUR 80 per TB-month) | Leaseweb Public Cloud storage pricing. |
| Backup object storage (S3 on-demand) | EUR 0.01733 per GB-month (EUR 17.33 per TB-month) | Leaseweb Object Storage pricing. |
| Billable egress (over included allowance) | EUR 2.20 per TB | Leaseweb data transfer pricing. |
| Backup restore/read egress reserve | EUR 2.20 per TB | Same egress unit used as ROM reserve. |
| FinOps reserve | 15% of subtotal | Covers support, IPs, small overages, and measurement error in ROM stage. |

## Monthly Baseline by Sizing Option
Formula:  
`Monthly Total = Servers + Primary Storage + Bandwidth + Backups + 15% FinOps reserve`

| Cost Line | Cheap MVP | Balanced | More HA |
|---|---:|---:|---:|
| Servers | EUR 217.71 | EUR 723.70 | EUR 1,086.15 |
| Primary storage | EUR 120.00 | EUR 320.00 | EUR 800.00 |
| Bandwidth (billable egress) | EUR 17.60 | EUR 39.60 | EUR 132.00 |
| Backups (object + restore reserve) | EUR 55.29 | EUR 145.24 | EUR 364.20 |
| Subtotal | EUR 410.60 | EUR 1,228.54 | EUR 2,382.35 |
| FinOps reserve (15%) | EUR 61.59 | EUR 184.28 | EUR 357.35 |
| **Total / month (ROM)** | **EUR 472.19** | **EUR 1,412.82** | **EUR 2,739.70** |

### Resource assumptions behind each option
| Option | Compute footprint | Storage footprint | Traffic + backup footprint |
|---|---|---|---|
| Cheap MVP | 3 x `R3.XLARGE` (combined control-plane/worker) | 1.5 TB primary block | 8 TB/month billable egress, 3 TB backup object data, 1.5 TB restore drill egress |
| Balanced | 5 x `R3.2XLARGE` (3 cp+worker + 2 worker headroom) | 4 TB primary block | 18 TB/month billable egress, 8 TB backup object data, 3 TB restore drill egress |
| More HA | 3 x `R3.XLARGE` control-plane + 6 x `R3.2XLARGE` workers | 10 TB primary block | 60 TB/month billable egress, 20 TB backup object data, 8 TB restore drill egress |

## Cost Drivers and What Changes at 10x Usage
| Driver | Why It Scales | 10x Usage Change | FinOps Control |
|---|---|---|---|
| Worker compute | Most app workloads are CPU/RAM-driven | Move from ~5 worker-equivalent nodes to ~30+; dedicated node pools become mandatory | Bin-packing targets, per-namespace quotas, autoscaling limits |
| Persistent storage | Longhorn replica factor multiplies physical storage | Logical 4 TB can become 40 TB logical and 80-120 TB physical | Charge by logical TB, set retention policies, tier hot vs cold data |
| Backup retention | Snapshot + WAL retention grows with data and compliance windows | Backup object footprint moves from single-digit TB to tens of TB | Retention class policy, immutable tiers only for critical datasets |
| Egress | APIs + object downloads dominate internet transfer | 18 TB/month can become 180+ TB/month | Per-tenant egress budgets, CDN/cache for read-heavy paths |
| Database HA | Write load + availability requirements increase | From 1 small CNPG cluster to multiple dedicated clusters with replicas | Managed DB pricing with vCPU + storage components and SLA tiers |
| Observability data | Logs/metrics volume grows faster than infra spend | Loki/metrics retention costs become meaningful | Sample rates, tiered retention, archive older data to cheaper object tier |

At 10x usage, architecture should change from one mixed cluster to at least:
1. Dedicated production cluster (non-prod split out).
2. Separate control-plane and worker pools.
3. Dedicated Postgres node group and backup throughput tuning.
4. Tiered observability retention (short hot, longer cold).

## Recommended Pricing Skeleton (for FreshCloud offer)
This is a pricing skeleton, not final list price. It is designed to keep gross margin healthy while the platform is still small.

| SKU | Suggested price | Notes |
|---|---:|---|
| Node unit (4 vCPU / 30 GiB equivalent) | EUR 165 per node-month | Covers compute COGS + shared platform overhead. |
| Persistent storage | EUR 269 per logical TB-month | Intended to cover replication + backups + restore testing overhead. |
| Managed Postgres | EUR 249 base per cluster-month + EUR 36 per vCPU-month + EUR 299 per TB-month | Base fee covers operations, patching, monitoring, and backup/restore drills. |

## Simple Break-Even Story
Using the **Balanced** run-rate (EUR 1,412.82/month):

- Standard tenant bundle assumption:
  - 2 node units
  - 1 TB persistent storage
  - 1 managed Postgres (2 vCPU, 200 GB)
- Revenue per tenant from skeleton:
  - Nodes: `2 x EUR 165 = EUR 330`
  - Storage: `1 x EUR 269 = EUR 269`
  - Managed DB: `EUR 249 + (2 x EUR 36) + (0.2 x EUR 299) = EUR 380.80`
  - Total per tenant: `EUR 979.80`

Break-even in this ROM is roughly **2 standard tenants** (`2 x EUR 979.80 = EUR 1,959.60`), after which additional tenants mostly fund scale-out and margin.

## Scale Triggers (Operational + Financial)
| Trigger | Threshold | Required Action |
|---|---|---|
| Compute saturation | Cluster CPU > 65% for 14 days | Add worker pool capacity (minimum +2 workers) |
| Storage pressure | Primary storage > 70% for 7 days | Add capacity and enforce retention cleanup within same sprint |
| Backup risk | Restore test cannot meet RTO in 2 consecutive drills | Increase backup bandwidth/object throughput and revisit retention class |
| DB performance | p95 DB latency > 20% over SLO for 7 days | Split DB to dedicated node pool and raise managed DB tier |
| FinOps margin compression | Gross margin < 45% for 2 months | Reprice SKUs and/or move to next sizing option |

## To Verify with Leaseweb (Cost-Specific)
- [ ] Confirm included traffic per instance and whether this offsets the egress model above.
- [ ] Confirm whether transfer pricing differs for object storage egress vs public cloud egress in contracted plan.
- [ ] Confirm support package costs and whether extra managed support should be modeled as fixed monthly spend.
- [ ] Confirm regional price differences and data-transfer charges between zones/regions.
- [ ] Confirm VAT/currency handling in contract (EUR list vs billed currency).

## References
- Leaseweb Public Cloud pricing: https://www.leaseweb.com/en/products-services/public-cloud/pricing
- Leaseweb Public Cloud SLA and transfer/storage rates: https://www.leaseweb.com/en/products-services/public-cloud/service-level-agreement
- Leaseweb Object Storage pricing: https://www.leaseweb.com/en/products-services/storage-solutions/object-storage/pricing
