import random

import instana
import os
import sys
import time
import logging
import uuid
import json
import requests
import traceback
from flask import Flask
from flask import Response
from flask import request
from flask import jsonify
from rabbitmq import Publisher
# Prometheus
import prometheus_client
from prometheus_client import Counter, Histogram, Gauge

app = Flask(__name__)
app.logger.setLevel(logging.INFO)

CART = os.getenv('CART_HOST', 'cart')
USER = os.getenv('USER_HOST', 'user')
PAYMENT_GATEWAY = os.getenv('PAYMENT_GATEWAY', 'https://paypal.com/')

# Prometheus
PromMetrics = {}
PromMetrics['SOLD_COUNTER'] = Counter('sold_count', 'Running count of items sold')
PromMetrics['AUS'] = Histogram('units_sold', 'Average Unit Sale', buckets=(1, 2, 5, 10, 100))
PromMetrics['AVS'] = Histogram('cart_value', 'Average Value Sale', buckets=(100, 200, 500, 1000, 2000, 5000, 10000))

# SRE Business Metrics
PromMetrics['PAYMENT_REQUESTS'] = Counter('payment_requests_total', 'Total payment requests', ['status'])
PromMetrics['PAYMENT_DURATION'] = Histogram('payment_duration_seconds', 'Payment processing duration')
PromMetrics['PAYMENT_FAILURES'] = Counter('payment_failures_total', 'Payment failures', ['error_type'])
PromMetrics['ACTIVE_PAYMENTS'] = Gauge('active_payments', 'Currently processing payments')
PromMetrics['GATEWAY_ERRORS'] = Counter('payment_gateway_errors_total', 'Payment gateway errors', ['gateway'])


@app.errorhandler(Exception)
def exception_handler(err):
    app.logger.error(str(err))
    return str(err), 500

@app.route('/health', methods=['GET'])
def health():
    return 'OK'

# Prometheus
@app.route('/metrics', methods=['GET'])
def metrics():
    res = []
    for m in PromMetrics.values():
        res.append(prometheus_client.generate_latest(m))

    return Response(res, mimetype='text/plain')


@app.route('/pay/<id>', methods=['POST'])
def pay(id):
    start_time = time.time()
    PromMetrics['ACTIVE_PAYMENTS'].inc()  # Track active payments
    
    try:
        app.logger.info('payment for {}'.format(id))
        cart = request.get_json()
        app.logger.info(cart)

        anonymous_user = True

        # check user exists
        try:
            req = requests.get('http://{user}:8080/check/{id}'.format(user=USER, id=id))
        except requests.exceptions.RequestException as err:
            app.logger.error(err)
            PromMetrics['PAYMENT_FAILURES'].labels(error_type='user_service_error').inc()
            PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
            return str(err), 500
        if req.status_code == 200:
            anonymous_user = False
        elif req.status_code != 404:  # 404 is expected for anonymous users
            PromMetrics['PAYMENT_FAILURES'].labels(error_type='user_service_error').inc()
            PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
            return 'user service error', req.status_code

        # check that the cart is valid
        has_shipping = False
        for item in cart.get('items'):
            if item.get('sku') == 'SHIP':
                has_shipping = True

        if cart.get('total', 0) == 0 or has_shipping == False:
            app.logger.warn('cart not valid')
            PromMetrics['PAYMENT_FAILURES'].labels(error_type='invalid_cart').inc()
            PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
            return 'cart not valid', 400

        # dummy call to payment gateway
        try:
            req = requests.get(PAYMENT_GATEWAY)
            app.logger.info('{} returned {}'.format(PAYMENT_GATEWAY, req.status_code))
        except requests.exceptions.RequestException as err:
            app.logger.error(err)
            PromMetrics['GATEWAY_ERRORS'].labels(gateway='paypal').inc()
            PromMetrics['PAYMENT_FAILURES'].labels(error_type='gateway_error').inc()
            PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
            return str(err), 500
        if req.status_code != 200:
            PromMetrics['GATEWAY_ERRORS'].labels(gateway='paypal').inc()
            PromMetrics['PAYMENT_FAILURES'].labels(error_type='gateway_error').inc()
            PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
            return 'payment error', req.status_code

        # Prometheus - items purchased
        item_count = countItems(cart.get('items', []))
        PromMetrics['SOLD_COUNTER'].inc(item_count)
        PromMetrics['AUS'].observe(item_count)
        PromMetrics['AVS'].observe(cart.get('total', 0))

        # Generate order id
        orderid = str(uuid.uuid4())
        queueOrder({ 'orderid': orderid, 'user': id, 'cart': cart })

        # add to order history
        if not anonymous_user:
            try:
                req = requests.post('http://{user}:8080/order/{id}'.format(user=USER, id=id),
                        data=json.dumps({'orderid': orderid, 'cart': cart}),
                        headers={'Content-Type': 'application/json'})
                app.logger.info('order history returned {}'.format(req.status_code))
            except requests.exceptions.RequestException as err:
                app.logger.error(err)
                PromMetrics['PAYMENT_FAILURES'].labels(error_type='user_service_error').inc()
                PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
                return str(err), 500
            if req.status_code != 200:
                PromMetrics['PAYMENT_FAILURES'].labels(error_type='user_service_error').inc()
                PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
                return 'order history update error', req.status_code

        # delete cart
        try:
            req = requests.delete('http://{cart}:8080/cart/{id}'.format(cart=CART, id=id));
            app.logger.info('cart delete returned {}'.format(req.status_code))
        except requests.exceptions.RequestException as err:
            app.logger.error(err)
            PromMetrics['PAYMENT_FAILURES'].labels(error_type='cart_service_error').inc()
            PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
            return str(err), 500
        if req.status_code != 200:
            PromMetrics['PAYMENT_FAILURES'].labels(error_type='cart_service_error').inc()
            PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
            return 'cart delete error', req.status_code

        # Success metrics
        PromMetrics['PAYMENT_REQUESTS'].labels(status='success').inc()
        return jsonify({ 'orderid': orderid })
        
    finally:
        # Always record duration and decrement active payments
        duration = time.time() - start_time
        PromMetrics['PAYMENT_DURATION'].observe(duration)
        PromMetrics['ACTIVE_PAYMENTS'].dec()


def queueOrder(order):
    app.logger.info('queue order')

    # For screenshot demo requirements optionally add in a bit of delay
    delay = int(os.getenv('PAYMENT_DELAY_MS', 0))
    time.sleep(delay / 1000)

    headers = {}
    publisher.publish(order, headers)


def countItems(items):
    count = 0
    for item in items:
        if item.get('sku') != 'SHIP':
            count += item.get('qty')

    return count


# RabbitMQ
publisher = Publisher(app.logger)

if __name__ == "__main__":
    sh = logging.StreamHandler(sys.stdout)
    sh.setLevel(logging.INFO)
    fmt = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    app.logger.info('Payment gateway {}'.format(PAYMENT_GATEWAY))
    port = int(os.getenv("SHOP_PAYMENT_PORT", "8080"))
    app.logger.info('Starting on port {}'.format(port))
    app.run(host='0.0.0.0', port=port)
# GitOps test
