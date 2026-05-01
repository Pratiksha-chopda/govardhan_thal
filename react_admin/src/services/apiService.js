import axios from 'axios';

/**
 * apiService — Standardized Axios instance for backend communication.
 * Uses NEXT_PUBLIC_API_URL env variable, defaults to localhost:3000.
 * Set NEXT_PUBLIC_API_URL in .env.local to override (e.g., for remote access).
 */

const BASE_HOST = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
const API_URL = `${BASE_HOST}/api/v1/`;

const apiService = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor
apiService.interceptors.request.use(
  (config) => {
    // 1. Force absolute URL if relative path provided to prevent Next.js port collision (3001 vs 3000)
    // Strip leading slash if present to avoid wiping out baseURL path segments
    if (config.url && config.url.startsWith('/')) {
      config.url = config.url.substring(1);
    }

    // 2. Attach Authorization token
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('adminToken');
      if (token && config.headers) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response Interceptor
apiService.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response && error.response.status === 401) {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('adminToken');
        // Redirect to login if unauthorized
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export default apiService;
