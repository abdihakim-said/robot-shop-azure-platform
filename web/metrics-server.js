const express = require('express');
const promClient = require('prom-client');
const fs = require('fs');
const path = require('path');

const app = express();
const register = new promClient.Registry();

// Web Service SRE Metrics
const webMetrics = {
    // Page Response Times
    pageResponseTime: new promClient.Histogram({
        name: 'web_page_response_time_seconds',
        help: 'Response time for web pages',
        labelNames: ['page', 'method', 'status_code'],
        buckets: [0.1, 0.3, 0.5, 0.7, 1.0, 3.0, 5.0, 7.0, 10.0],
        registers: [register]
    }),

    // HTTP Requests
    httpRequests: new promClient.Counter({
        name: 'web_http_requests_total',
        help: 'Total HTTP requests',
        labelNames: ['method', 'route', 'status_code'],
        registers: [register]
    }),

    // Error Rates
    httpErrors: new promClient.Counter({
        name: 'web_http_errors_total',
        help: 'Total HTTP errors',
        labelNames: ['error_type', 'route'],
        registers: [register]
    }),

    // User Sessions
    activeSessions: new promClient.Gauge({
        name: 'web_active_sessions',
        help: 'Currently active user sessions',
        registers: [register]
    }),

    // Page Views
    pageViews: new promClient.Counter({
        name: 'web_page_views_total',
        help: 'Total page views',
        labelNames: ['page'],
        registers: [register]
    }),

    // API Calls to Backend Services
    backendCalls: new promClient.Counter({
        name: 'web_backend_calls_total',
        help: 'Calls to backend services',
        labelNames: ['service', 'status'],
        registers: [register]
    }),

    // User Actions
    userActions: new promClient.Counter({
        name: 'web_user_actions_total',
        help: 'User actions on the website',
        labelNames: ['action', 'page'],
        registers: [register]
    })
};

// Middleware to track metrics
app.use((req, res, next) => {
    const start = Date.now();
    
    // Track request
    webMetrics.httpRequests.inc({
        method: req.method,
        route: req.path,
        status_code: res.statusCode
    });

    // Track page views for GET requests
    if (req.method === 'GET' && !req.path.startsWith('/api')) {
        webMetrics.pageViews.inc({ page: req.path });
    }

    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        
        // Track response time
        webMetrics.pageResponseTime.observe({
            page: req.path,
            method: req.method,
            status_code: res.statusCode
        }, duration);

        // Track errors
        if (res.statusCode >= 400) {
            const errorType = res.statusCode >= 500 ? 'server_error' : 'client_error';
            webMetrics.httpErrors.inc({
                error_type: errorType,
                route: req.path
            });
        }
    });

    next();
});

// Simulate some user session tracking
let sessionCount = 0;
setInterval(() => {
    // Simulate session fluctuation (in real app, this would be actual session tracking)
    sessionCount = Math.floor(Math.random() * 50) + 10;
    webMetrics.activeSessions.set(sessionCount);
}, 30000);

// API endpoints to simulate backend calls
app.get('/api/catalogue', (req, res) => {
    webMetrics.backendCalls.inc({ service: 'catalogue', status: 'success' });
    res.json({ message: 'Catalogue data' });
});

app.get('/api/cart', (req, res) => {
    webMetrics.backendCalls.inc({ service: 'cart', status: 'success' });
    res.json({ message: 'Cart data' });
});

app.post('/api/user/login', (req, res) => {
    webMetrics.userActions.inc({ action: 'login', page: 'login' });
    webMetrics.backendCalls.inc({ service: 'user', status: 'success' });
    res.json({ message: 'Login successful' });
});

app.post('/api/cart/add', (req, res) => {
    webMetrics.userActions.inc({ action: 'add_to_cart', page: 'product' });
    webMetrics.backendCalls.inc({ service: 'cart', status: 'success' });
    res.json({ message: 'Item added to cart' });
});

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(register.metrics());
});

// Start metrics server
const port = process.env.METRICS_PORT || 9090;
app.listen(port, () => {
    console.log(`Web service metrics server running on port ${port}`);
    console.log('Metrics available at /metrics');
});

module.exports = app;
