// apiConfig.js - Centralized API configuration for ALL place types
// This file contains the base URL for the Muslim Vegukin API

const API_CONFIG = {
  // Base URL for the Flask API deployed on Render/Fly.io
  //BASE_URL: 'https://muslim-vegukin-api.fly.dev',
  BASE_URL: 'https://vegukin-api.duckdns.org/',
  
  // API endpoints
  ENDPOINTS: {
    // Generic places endpoint (replaces individual mosque/restaurant/shop endpoints)
    PLACES_NEARBY: '/api/places/nearby',
    PLACES_BY_ADDRESS: '/api/places/by-address',
    PLACE_DETAIL: '/api/place',
    
    // Legacy endpoints (for backward compatibility)
    MOSQUES_NEARBY: '/api/places/nearby?building_type=Masjid',
    MOSQUES_BY_ADDRESS: '/api/places/by-address?building_type=Masjid',
    MOSQUE_DETAIL: '/api/place',
    
    RESTAURANTS_NEARBY: '/api/places/nearby?building_type=Oshxona',
    RESTAURANTS_BY_ADDRESS: '/api/places/by-address?building_type=Oshxona',
    RESTAURANT_DETAIL: '/api/place',
    
    SHOPS_NEARBY: '/api/places/nearby?building_type=Do\'kon',
    SHOPS_BY_ADDRESS: '/api/places/by-address?building_type=Do\'kon',
    SHOP_DETAIL: '/api/place',
    
    // Health & Stats
    HEALTH: '/api/health',
    STATS: '/api/stats',
    
    // Review submission
    REVIEW_SUBMIT: '/api/review/submit'
  },
  
  // Default settings
  DEFAULTS: {
    LIMIT: 5,  // Number of results to fetch
    TIMEOUT: 30000  // 30 seconds (for cold starts on Render free tier)
  }
};

// Helper function to build full API URLs
function getApiUrl(endpoint, params = {}) {
  const url = new URL(API_CONFIG.BASE_URL + endpoint);
  
  // Add query parameters
  Object.keys(params).forEach(key => {
    if (params[key] !== undefined && params[key] !== null) {
      url.searchParams.append(key, params[key]);
    }
  });
  
  return url.toString();
}

// Make available globally
window.API_CONFIG = API_CONFIG;
window.getApiUrl = getApiUrl;

console.log('✅ API Config loaded:', API_CONFIG.BASE_URL);