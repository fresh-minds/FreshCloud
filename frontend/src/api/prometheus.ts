interface PrometheusResponse<T> {
  status: string;
  data: T;
}

interface PrometheusVectorResult {
  metric: Record<string, string>;
  value: [number, string];
}

interface PrometheusQueryData {
  resultType: string;
  result: PrometheusVectorResult[];
}

const defaultPrometheusUrl = import.meta.env.VITE_PROMETHEUS_URL;

export async function queryPrometheusInstant(
  query: string,
  baseUrl = defaultPrometheusUrl
): Promise<PrometheusVectorResult[]> {
  if (!baseUrl) {
    throw new Error('VITE_PROMETHEUS_URL is not configured');
  }

  const url = new URL('/api/v1/query', baseUrl);
  url.searchParams.set('query', query);

  const response = await fetch(url.toString(), {
    headers: {
      Accept: 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error(`Prometheus query failed: ${response.status}`);
  }

  const payload = (await response.json()) as PrometheusResponse<PrometheusQueryData>;

  if (payload.status !== 'success') {
    throw new Error('Prometheus returned non-success status');
  }

  return payload.data.result;
}

export function parsePrometheusValue(result: PrometheusVectorResult | undefined): number | null {
  if (!result) {
    return null;
  }

  const parsed = Number(result.value[1]);
  return Number.isFinite(parsed) ? parsed : null;
}
