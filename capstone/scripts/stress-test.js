import http from 'k6/http';
import { check, sleep } from 'k6';

// 👇 CONFIGURATION
export const options = {
  stages: [
    { duration: '30s', target: 300 }, 
    { duration: '3m',  target: 500 }, 
    { duration: '10s', target: 0 }, 
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], 
    http_req_failed: ['rate<0.05'], 
  },
};

export default function () {
  // 1. Get URL from Environment Variable
  const url = __ENV.APP_URL;

  // 2. Safety Check (Must be inside the function)
  if (!url) {
    throw new Error('ERROR: APP_URL environment variable is missing! Did you run the PowerShell command?');
  }

  // 3. Run the test
  const res = http.get(url);

  check(res, { 'status was 200': (r) => r.status == 200 });

  sleep(0.1); 
}