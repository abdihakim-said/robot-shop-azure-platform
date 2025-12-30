// Test all services - secure pipeline
const instana = require('@instana/collector');
// init tracing
// MUST be done before loading anything else!
// Test: Modern GitOps + ArgoCD credentials + SRE resources
instana({
    tracing: {
        enabled: true
    }
});

const redis = require('redis');
const axios = require('axios');
const bodyParser = require('body-parser');
// Test build pipeline trigger - fixed validation
// Trigger pipeline test - AKS credentials fix
const express = require('express');
const pino = require('pino');
const expPino = require('express-pino-logger');
// Prometheus
const promClient = require('prom-client');
const Registry = promClient.Registry;
const register = new Registry();

// Original metric
const counter = new promClient.Counter({
    name: 'items_added',
    help: 'running count of items added to cart',
    registers: [register]
});

// SRE Cart Service Metrics
const cartMetrics = {
    // Cart Operations Performance
    cartOperationDuration: new promClient.Histogram({
        name: 'cart_operation_duration_seconds',
        help: 'Duration of cart operations',
        labelNames: ['operation', 'status'],
        buckets: [0.1, 0.3, 0.5, 1.0, 2.0, 5.0],
        registers: [register]
    }),

    // Cart Operations Count
    cartOperations: new promClient.Counter({
        name: 'cart_operations_total',
        help: 'Total cart operations',
        labelNames: ['operation', 'status'],
        registers: [register]
    }),

    // Cart Errors
    cartErrors: new promClient.Counter({
        name: 'cart_errors_total',
        help: 'Cart operation errors',
        labelNames: ['operation', 'error_type'],
        registers: [register]
    }),

    // Active Carts
    activeCarts: new promClient.Gauge({
        name: 'cart_active_carts',
        help: 'Number of active carts',
        registers: [register]
    }),

    // Items per Cart
    itemsPerCart: new promClient.Histogram({
        name: 'cart_items_per_cart',
        help: 'Number of items per cart',
        buckets: [1, 2, 5, 10, 20, 50],
        registers: [register]
    }),

    // Cart Value
    cartValue: new promClient.Histogram({
        name: 'cart_value_total',
        help: 'Total value of items in cart',
        buckets: [10, 25, 50, 100, 200, 500, 1000],
        registers: [register]
    }),

    // Redis Connection
    redisConnections: new promClient.Counter({
        name: 'cart_redis_connections_total',
        help: 'Redis connection attempts',
        labelNames: ['status'],
        registers: [register]
    }),

    // Cart Abandonment Tracking
    cartAbandonment: new promClient.Counter({
        name: 'cart_abandonment_total',
        help: 'Cart abandonment events',
        labelNames: ['reason'],
        registers: [register]
    })
};

// Helper function to track cart operations
function trackCartOperation(operation, startTime, status = 'success', errorType = null) {
    const duration = (Date.now() - startTime) / 1000;
    
    cartMetrics.cartOperationDuration.observe({ operation, status }, duration);
    cartMetrics.cartOperations.inc({ operation, status });
    
    if (status === 'error' && errorType) {
        cartMetrics.cartErrors.inc({ operation, error_type: errorType });
    }
}

var redisConnected = false;

var redisHost = process.env.REDIS_HOST || 'redis'
var redisPassword = process.env.REDIS_PASSWORD || ''  // From Azure Key Vault
var catalogueHost = process.env.CATALOGUE_HOST || 'catalogue'

const logger = pino({
    level: 'info',
    prettyPrint: false,
    useLevelLabels: true
});
const expLogger = expPino({
    logger: logger
});

const app = express();

app.use(expLogger);

app.use((req, res, next) => {
    res.set('Timing-Allow-Origin', '*');
    res.set('Access-Control-Allow-Origin', '*');
    next();
});

app.use((req, res, next) => {
    let dcs = [
        "asia-northeast2",
        "asia-south1",
        "europe-west3",
        "us-east1",
        "us-west1"
    ];
    let span = instana.currentSpan();
    span.annotate('custom.sdk.tags.datacenter', dcs[Math.floor(Math.random() * dcs.length)]);

    next();
});

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.get('/health', (req, res) => {
    var stat = {
        app: 'OK',
        redis: redisConnected
    };
    res.json(stat);
});

// Prometheus
app.get('/metrics', (req, res) => {
    res.header('Content-Type', 'text/plain');
    res.send(register.metrics());
});


// get cart with id
app.get('/cart/:id', (req, res) => {
    const startTime = Date.now();
    
    redisClient.get(req.params.id, (err, data) => {
        if(err) {
            req.log.error('ERROR', err);
            trackCartOperation('get_cart', startTime, 'error', 'redis_error');
            res.status(500).send(err);
        } else {
            if(data == null) {
                trackCartOperation('get_cart', startTime, 'error', 'cart_not_found');
                res.status(404).send('cart not found');
            } else {
                trackCartOperation('get_cart', startTime, 'success');
                
                // Track cart metrics
                try {
                    const cart = JSON.parse(data);
                    if (cart.items && cart.items.length > 0) {
                        cartMetrics.itemsPerCart.observe(cart.items.length);
                        
                        // Calculate cart value
                        const totalValue = cart.items.reduce((sum, item) => sum + (item.price * item.qty), 0);
                        cartMetrics.cartValue.observe(totalValue);
                    }
                } catch (parseErr) {
                    req.log.warn('Failed to parse cart data for metrics');
                }
                
                res.set('Content-Type', 'application/json');
                res.send(data);
            }
        }
    });
});

// delete cart with id
app.delete('/cart/:id', (req, res) => {
    const startTime = Date.now();
    
    redisClient.del(req.params.id, (err, data) => {
        if(err) {
            req.log.error('ERROR', err);
            trackCartOperation('delete_cart', startTime, 'error', 'redis_error');
            res.status(500).send(err);
        } else {
            if(data == 1) {
                trackCartOperation('delete_cart', startTime, 'success');
                cartMetrics.cartAbandonment.inc({ reason: 'checkout_completed' });
                res.send('OK');
            } else {
                trackCartOperation('delete_cart', startTime, 'error', 'cart_not_found');
                res.status(404).send('cart not found');
            }
        }
    });
});

// rename cart i.e. at login
app.get('/rename/:from/:to', (req, res) => {
    redisClient.get(req.params.from, (err, data) => {
        if(err) {
            req.log.error('ERROR', err);
            res.status(500).send(err);
        } else {
            if(data == null) {
                res.status(404).send('cart not found');
            } else {
                var cart = JSON.parse(data);
                saveCart(req.params.to, cart).then((data) => {
                    res.json(cart);
                }).catch((err) => {
                    req.log.error(err);
                    res.status(500).send(err);
                });
            }
        }
    });
});

// update/create cart
app.get('/add/:id/:sku/:qty', (req, res) => {
    const startTime = Date.now();
    
    // check quantity
    var qty = parseInt(req.params.qty);
    if(isNaN(qty)) {
        req.log.warn('quantity not a number');
        trackCartOperation('add_item', startTime, 'error', 'invalid_quantity');
        res.status(400).send('quantity must be a number');
        return;
    } else if(qty < 1) {
        req.log.warn('quantity less than one');
        trackCartOperation('add_item', startTime, 'error', 'invalid_quantity');
        res.status(400).send('quantity has to be greater than zero');
        return;
    }

    // look up product details
    getProduct(req.params.sku).then((product) => {
        req.log.info('got product', product);
        if(!product) {
            trackCartOperation('add_item', startTime, 'error', 'product_not_found');
            res.status(404).send('product not found');
            return;
        }
        // is the product in stock?
        if(product.instock == 0) {
            trackCartOperation('add_item', startTime, 'error', 'out_of_stock');
            res.status(404).send('out of stock');
            return;
        }
        // does the cart already exist?
        redisClient.get(req.params.id, (err, data) => {
            if(err) {
                req.log.error('ERROR', err);
                trackCartOperation('add_item', startTime, 'error', 'redis_error');
                res.status(500).send(err);
            } else {
                var cart;
                if(data == null) {
                    // create new cart
                    cart = {
                        total: 0,
                        tax: 0,
                        items: []
                    };
                } else {
                    cart = JSON.parse(data);
                }
                req.log.info('got cart', cart);
                // add sku to cart
                var item = {
                    qty: qty,
                    sku: req.params.sku,
                    name: product.name,
                    price: product.price,
                    subtotal: qty * product.price
                };
                var list = mergeList(cart.items, item, qty);
                cart.items = list;
                cart.total = calcTotal(cart.items);
                // work out tax
                cart.tax = calcTax(cart.total);

                // save the new cart
                saveCart(req.params.id, cart).then((data) => {
                    counter.inc(qty);
                    trackCartOperation('add_item', startTime, 'success');
                    
                    // Track cart metrics
                    cartMetrics.itemsPerCart.observe(cart.items.length);
                    cartMetrics.cartValue.observe(cart.total);
                    
                    res.json(cart);
                }).catch((err) => {
                    req.log.error(err);
                    trackCartOperation('add_item', startTime, 'error', 'save_failed');
                    res.status(500).send(err);
                });
            }
        });
    }).catch((err) => {
        req.log.error(err);
        res.status(500).send(err);
    });
});

// update quantity - remove item when qty == 0
app.get('/update/:id/:sku/:qty', (req, res) => {
    // check quantity
    var qty = parseInt(req.params.qty);
    if(isNaN(qty)) {
        req.log.warn('quanity not a number');
        res.status(400).send('quantity must be a number');
        return;
    } else if(qty < 0) {
        req.log.warn('quantity less than zero');
        res.status(400).send('negative quantity not allowed');
        return;
    }

    // get the cart
    redisClient.get(req.params.id, (err, data) => {
        if(err) {
            req.log.error('ERROR', err);
            res.status(500).send(err);
        } else {
            if(data == null) {
                res.status(404).send('cart not found');
            } else {
                var cart = JSON.parse(data);
                var idx;
                var len = cart.items.length;
                for(idx = 0; idx < len; idx++) {
                    if(cart.items[idx].sku == req.params.sku) {
                        break;
                    }
                }
                if(idx == len) {
                    // not in list
                    res.status(404).send('not in cart');
                } else {
                    if(qty == 0) {
                        cart.items.splice(idx, 1);
                    } else {
                        cart.items[idx].qty = qty;
                        cart.items[idx].subtotal = cart.items[idx].price * qty;
                    }
                    cart.total = calcTotal(cart.items);
                    // work out tax
                    cart.tax = calcTax(cart.total);
                    saveCart(req.params.id, cart).then((data) => {
                        res.json(cart);
                    }).catch((err) => {
                        req.log.error(err);
                        res.status(500).send(err);
                    });
                }
            }
        }
    });
});

// add shipping
app.post('/shipping/:id', (req, res) => {
    var shipping = req.body;
    if(shipping.distance === undefined || shipping.cost === undefined || shipping.location == undefined) {
        req.log.warn('shipping data missing', shipping);
        res.status(400).send('shipping data missing');
    } else {
        // get the cart
        redisClient.get(req.params.id, (err, data) => {
            if(err) {
                req.log.error('ERROR', err);
                res.status(500).send(err);
            } else {
                if(data == null) {
                    req.log.info('no cart for', req.params.id);
                    res.status(404).send('cart not found');
                } else {
                    var cart = JSON.parse(data);
                    var item = {
                        qty: 1,
                        sku: 'SHIP',
                        name: 'shipping to ' + shipping.location,
                        price: shipping.cost,
                        subtotal: shipping.cost
                    };
                    // check shipping already in the cart
                    var idx;
                    var len = cart.items.length;
                    for(idx = 0; idx < len; idx++) {
                        if(cart.items[idx].sku == item.sku) {
                            break;
                        }
                    }
                    if(idx == len) {
                        // not already in cart
                        cart.items.push(item);
                    } else {
                        cart.items[idx] = item;
                    }
                    cart.total = calcTotal(cart.items);
                    // work out tax
                    cart.tax = calcTax(cart.total);

                    // save the updated cart
                    saveCart(req.params.id, cart).then((data) => {
                        res.json(cart);
                    }).catch((err) => {
                        req.log.error(err);
                        res.status(500).send(err);
                    });
                }
            }
        });
    }
});

function mergeList(list, product, qty) {
    var inlist = false;
    // loop through looking for sku
    var idx;
    var len = list.length;
    for(idx = 0; idx < len; idx++) {
        if(list[idx].sku == product.sku) {
            inlist = true;
            break;
        }
    }

    if(inlist) {
        list[idx].qty += qty;
        list[idx].subtotal = list[idx].price * list[idx].qty;
    } else {
        list.push(product);
    }

    return list;
}

function calcTotal(list) {
    var total = 0;
    for(var idx = 0, len = list.length; idx < len; idx++) {
        total += list[idx].subtotal;
    }

    return total;
}

function calcTax(total) {
    // tax @ 20%
    return (total - (total / 1.2));
}

function getProduct(sku) {
    return axios.get('http://' + catalogueHost + ':8080/product/' + sku)
        .then(response => response.data)
        .catch(err => {
            if (err.response && err.response.status !== 200) {
                return null;
            }
            throw err;
        });
}

function saveCart(id, cart) {
    logger.info('saving cart', cart);
    return new Promise((resolve, reject) => {
        redisClient.setex(id, 3600, JSON.stringify(cart), (err, data) => {
            if(err) {
                reject(err);
            } else {
                resolve(data);
            }
        });
    });
}

// connect to Redis
var redisClient = redis.createClient({
    host: redisHost,
    password: redisPassword || undefined  // Authenticate with Azure Key Vault password
});

redisClient.on('error', (e) => {
    logger.error('Redis ERROR', e);
    cartMetrics.redisConnections.inc({ status: 'error' });
    redisConnected = false;
});

redisClient.on('ready', (r) => {
    logger.info('Redis READY', r);
    cartMetrics.redisConnections.inc({ status: 'success' });
    redisConnected = true;
});

redisClient.on('connect', () => {
    logger.info('Redis CONNECTED');
    cartMetrics.redisConnections.inc({ status: 'connected' });
});

// Monitor active carts periodically
setInterval(() => {
    if (redisConnected) {
        redisClient.keys('*', (err, keys) => {
            if (!err && keys) {
                cartMetrics.activeCarts.set(keys.length);
            }
        });
    }
}, 30000); // Update every 30 seconds

// fire it up!
const port = process.env.CART_SERVER_PORT || '8080';
app.listen(port, () => {
    logger.info('Started on port', port);
});

// Test automatic deployment
// Auto-deploy test
// Final test
// DevSecOps pipeline test
// GitOps test - trigger all services
