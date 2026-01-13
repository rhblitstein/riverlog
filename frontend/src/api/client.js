const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080'

// Helper function for making API requests
async function apiRequest(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`
  
  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  }

  const response = await fetch(url, config)
  
  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.error || 'An error occurred')
  }

  // Handle 204 No Content responses
  if (response.status === 204) {
    return { success: true }
  }

  return response.json()
}

// Auth API calls
export const auth = {
  register: (data) => apiRequest('/api/v1/auth/register', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  
  login: (data) => apiRequest('/api/v1/auth/login', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  
  refresh: (token) => apiRequest('/api/v1/auth/refresh', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  }),
}

// Trip API calls
export const trips = {
  list: (token, params = {}) => {
    const query = new URLSearchParams(params).toString()
    return apiRequest(`/api/v1/trips?${query}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    })
  },
  
  get: (token, id) => apiRequest(`/api/v1/trips/${id}`, {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  }),
  
  create: (token, data) => apiRequest('/api/v1/trips', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify(data),
  }),
  
  update: (token, id, data) => apiRequest(`/api/v1/trips/${id}`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify(data),
  }),
  
  delete: (token, id) => apiRequest(`/api/v1/trips/${id}`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  }),
}

// User API calls
export const users = {
  me: (token) => apiRequest('/api/v1/users/me', {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  }),
  
  update: (token, data) => apiRequest('/api/v1/users/me', {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify(data),
  }),
}