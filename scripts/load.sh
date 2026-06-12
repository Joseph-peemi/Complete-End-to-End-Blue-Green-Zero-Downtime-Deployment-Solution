import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate   = new Rate('error_rate');
const apiLatency  = new Trend('api_latency', true);  // true = display in ms

export const options = {
  stages: [
    { duration: '10s', target: 10 },   // ramp up to 10 VUs
    { duration: '20s', target: 10 },   // hold at 10 VUs
    { duration: '10s', target: 0  },   // ramp down
  ],
  thresholds: {
    'http_req_failed':   ['rate<0.01'],   // < 1% requests can fail
    'http_req_duration': ['p(99)<2000'],  // p99 under 2 seconds
    'error_rate':        ['rate<0.01'],   // custom metric threshold
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  const responses = http.batch([
    ['GET', `${BASE_URL}/health`],
    ['GET', `${BASE_URL}/api/products`],
    ['GET', `${BASE_URL}/api/orders`],
  ]);

  responses.forEach((res, i) => {
    const passed = check(res, {
      'status is 200':     (r) => r.status === 200,
      'response time OK':  (r) => r.timings.duration < 2000,
      'no error in body':  (r) => !r.body.includes('"error"'),
    });

    errorRate.add(!passed);
    apiLatency.add(res.timings.duration);
  });

  sleep(1);   // 1 second think time between iterations per VU
}

export function handleSummary(data) {
  return {
    'load-test-results.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: false }),
  };
}