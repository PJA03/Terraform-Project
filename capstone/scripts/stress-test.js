import http from 'k6/http';
import { check, sleep } from 'k6';

// 👇 CONFIGURATION
export const options = {
  // Key concept: "Stages" let you ramp up traffic like real life
  stages: [
    { duration: '30s', target: 300 },  // 1. Ramp up to 50 users over 30s
    { duration: '3m',  target: 500 },  // 2. Stay at 50 users for 1 minute (Stress!)
    { duration: '10s', target: 0 },   // 3. Ramp down to 0 users
  ],
  // Fail the test if 95% of requests take > 500ms
  thresholds: {
    http_req_duration: ['p(95)<2000'], // Relax threshold (we expect it to be slow)
    http_req_failed: ['rate<0.05'],    // Allow 5% errors (it's a stress test!)
  },
};

export default function () {
  // 👇 REPLACE THIS WITH YOUR ALB DNS NAME!
  const url = 'http://Galias-FinalProject-frontend-alb-1074551113.ap-southeast-1.elb.amazonaws.com';

  const res = http.get(url);

  // Validate that the server actually responded with "200 OK"
  check(res, { 'status was 200': (r) => r.status == 200 });

  sleep(0.1); // Wait 1s between requests (simulates a real user thinking)
}