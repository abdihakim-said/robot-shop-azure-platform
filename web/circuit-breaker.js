const CircuitBreaker = require('opossum');

// Circuit breaker configuration
const circuitBreakerOptions = {
  timeout: 3000,        // 3 second timeout
  errorThresholdPercentage: 50,  // Open circuit at 50% error rate
  resetTimeout: 30000,  // Try again after 30 seconds
  rollingCountTimeout: 10000,    // 10 second rolling window
  rollingCountBuckets: 10,       // Number of buckets in window
  name: 'ServiceCircuitBreaker',
  group: 'robot-shop'
};

// Create circuit breakers for each service
const catalogueBreaker = new CircuitBreaker(callCatalogueService, circuitBreakerOptions);
const cartBreaker = new CircuitBreaker(callCartService, circuitBreakerOptions);
const userBreaker = new CircuitBreaker(callUserService, circuitBreakerOptions);

// Service call functions with circuit breaker
async function callCatalogueService(path) {
  const response = await fetch(`http://catalogue:8080${path}`);
  if (!response.ok) throw new Error(`Catalogue service error: ${response.status}`);
  return response.json();
}

async function callCartService(path, options = {}) {
  const response = await fetch(`http://cart:8080${path}`, options);
  if (!response.ok) throw new Error(`Cart service error: ${response.status}`);
  return response.json();
}

async function callUserService(path, options = {}) {
  const response = await fetch(`http://user:8080${path}`, options);
  if (!response.ok) throw new Error(`User service error: ${response.status}`);
  return response.json();
}

// Fallback functions
catalogueBreaker.fallback(() => ({ products: [], message: 'Catalogue temporarily unavailable' }));
cartBreaker.fallback(() => ({ items: [], message: 'Cart temporarily unavailable' }));
userBreaker.fallback(() => ({ user: null, message: 'User service temporarily unavailable' }));

// Export wrapped functions
module.exports = {
  getCatalogue: (path) => catalogueBreaker.fire(path),
  getCart: (path, options) => cartBreaker.fire(path, options),
  getUser: (path, options) => userBreaker.fire(path, options),
  
  // Circuit breaker status for monitoring
  getCircuitBreakerStats: () => ({
    catalogue: {
      state: catalogueBreaker.stats.state,
      failures: catalogueBreaker.stats.failures,
      successes: catalogueBreaker.stats.successes
    },
    cart: {
      state: cartBreaker.stats.state,
      failures: cartBreaker.stats.failures,
      successes: cartBreaker.stats.successes
    },
    user: {
      state: userBreaker.stats.state,
      failures: userBreaker.stats.failures,
      successes: userBreaker.stats.successes
    }
  })
};
