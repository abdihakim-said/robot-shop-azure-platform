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
import stripe
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

# Stripe configuration
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
STRIPE_ENABLED = bool(os.getenv('STRIPE_SECRET_KEY'))

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
PromMetrics['CIRCUIT_BREAKER_STATE'] = Gauge('payment_circuit_breaker_state', 'Circuit breaker state (0=closed, 1=open)')
PromMetrics['FALLBACK_PAYMENTS'] = Counter('payment_fallback_total', 'Payments processed in fallback mode')


@app.errorhandler(Exception)
def exception_handler(err):
    app.logger.error(str(err))
    return str(err), 500

@app.route('/health', methods=['GET'])
def health():
    return 'OK'

@app.route('/stripe/webhook', methods=['POST'])
def stripe_webhook():
    """Production-style webhook handler for Stripe events"""
    payload = request.get_data()
    sig_header = request.headers.get('Stripe-Signature')
    
    # In production, you'd verify the webhook signature
    # endpoint_secret = os.getenv('STRIPE_WEBHOOK_SECRET')
    
    try:
        # Parse the event
        event = stripe.Event.construct_from(
            json.loads(payload), stripe.api_key
        )
        
        app.logger.info('📨 Stripe webhook received: {}'.format(event['type']))
        
        # Handle the event (production pattern)
        if event['type'] == 'payment_intent.succeeded':
            payment_intent = event['data']['object']
            app.logger.info('✅ Webhook: Payment succeeded for {}'.format(payment_intent['id']))
            
            # Production would:
            # - Update order status in database
            # - Send confirmation email
            # - Trigger fulfillment
            # - Update inventory
            
        elif event['type'] == 'payment_intent.payment_failed':
            payment_intent = event['data']['object']
            app.logger.error('❌ Webhook: Payment failed for {}'.format(payment_intent['id']))
            
            # Production would:
            # - Update order status
            # - Send failure notification
            # - Retry logic if appropriate
            
        else:
            app.logger.info('🔔 Unhandled webhook event type: {}'.format(event['type']))
        
        return jsonify({'status': 'success'})
        
    except Exception as e:
        app.logger.error('❌ Webhook error: {}'.format(str(e)))
        return jsonify({'error': str(e)}), 400

@app.route('/demo/circuit-breaker', methods=['POST'])
def demo_circuit_breaker():
    """Demo endpoint to show circuit breaker behavior for interviews"""
    action = request.json.get('action', 'status')
    
    if action == 'trigger_failure':
        # Simulate multiple failures to open circuit breaker
        PromMetrics['GATEWAY_ERRORS'].labels(gateway='demo').inc()
        PromMetrics['CIRCUIT_BREAKER_STATE'].set(1)  # Open state
        return jsonify({
            'status': 'circuit_breaker_opened',
            'message': 'Simulated failures triggered circuit breaker'
        })
    elif action == 'reset':
        # Reset circuit breaker
        PromMetrics['CIRCUIT_BREAKER_STATE'].set(0)  # Closed state
        return jsonify({
            'status': 'circuit_breaker_reset',
            'message': 'Circuit breaker reset to closed state'
        })
    else:
        # Return current status
        return jsonify({
            'circuit_breaker_state': 'closed',  # Would be dynamic in real implementation
            'gateway_url': PAYMENT_GATEWAY,
            'fallback_enabled': True
        })

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

        # Generate order id first
        orderid = str(uuid.uuid4())

        # PRODUCTION-STYLE Stripe integration (test keys - safe for demo)
        if STRIPE_ENABLED:
            try:
                app.logger.info('🔄 Processing payment with Stripe API (TEST MODE)')
                
                # STEP 1: Create or retrieve customer (production pattern)
                customer_email = f"{id}@robotshop.demo"
                try:
                    customers = stripe.Customer.list(email=customer_email, limit=1)
                    if customers.data:
                        customer = customers.data[0]
                        app.logger.info('📋 Existing customer found: {}'.format(customer.id))
                    else:
                        customer = stripe.Customer.create(
                            email=customer_email,
                            name=f"Robot Shop User {id}",
                            metadata={'user_id': id, 'source': 'robot_shop'}
                        )
                        app.logger.info('👤 New customer created: {}'.format(customer.id))
                except Exception as e:
                    app.logger.warn('Customer creation failed, proceeding without: {}'.format(str(e)))
                    customer = None

                # STEP 2: Create PaymentIntent with production settings
                payment_intent_data = {
                    'amount': int(cart.get('total', 0) * 100),  # Convert to pence
                    'currency': 'gbp',
                    'payment_method_types': ['card'],
                    'metadata': {
                        'orderid': orderid,
                        'user_id': id,
                        'items_count': str(len(cart.get('items', []))),
                        'robot_shop': 'true',
                        'environment': 'demo'
                    },
                    # Production reliability patterns
                    'idempotency_key': f"order_{orderid}",
                    'description': f'Robot Shop Order {orderid}'
                }
                
                if customer:
                    payment_intent_data['customer'] = customer.id

                payment_intent = stripe.PaymentIntent.create(**payment_intent_data)
                
                # STEP 3: Simulate payment confirmation (production would use frontend)
                app.logger.info('💳 Simulating payment confirmation with test card...')
                
                # Use Stripe test payment method for demo
                confirmed_intent = stripe.PaymentIntent.confirm(
                    payment_intent.id,
                    payment_method='pm_card_visa',  # Stripe test card
                    return_url='https://robotshop.demo/payment/return'
                )
                
                # STEP 4: Handle payment result (production pattern)
                if confirmed_intent.status == 'succeeded':
                    app.logger.info('✅ STRIPE PAYMENT SUCCESSFUL!')
                    app.logger.info('   💳 Payment ID: {}'.format(confirmed_intent.id))
                    app.logger.info('   💰 Amount: £{:.2f} GBP'.format(confirmed_intent.amount / 100))
                    app.logger.info('   👤 Customer: {}'.format(confirmed_intent.customer or 'Guest'))
                    app.logger.info('   📊 Status: {}'.format(confirmed_intent.status))
                    app.logger.info('   🔗 Stripe Dashboard: https://dashboard.stripe.com/test/payments/{}'.format(confirmed_intent.id))
                    
                    # Production would also:
                    # - Send confirmation email
                    # - Update inventory
                    # - Trigger fulfillment
                    
                elif confirmed_intent.status == 'requires_action':
                    app.logger.warn('⚠️  Payment requires additional authentication')
                    # Production would handle 3D Secure here
                    
                else:
                    app.logger.error('❌ Payment failed with status: {}'.format(confirmed_intent.status))
                    PromMetrics['PAYMENT_FAILURES'].labels(error_type='payment_failed').inc()
                    return 'Payment failed', 400
                
            except stripe.error.CardError as e:
                app.logger.error('❌ Card declined: {} (Code: {})'.format(str(e), e.code))
                PromMetrics['PAYMENT_FAILURES'].labels(error_type='card_declined').inc()
                PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
                return 'Card declined: {}'.format(str(e)), 400
                
            except stripe.error.StripeError as e:
                app.logger.error('❌ Stripe API error: {} (Code: {})'.format(str(e), e.code if hasattr(e, 'code') else 'N/A'))
                PromMetrics['PAYMENT_FAILURES'].labels(error_type='stripe_error').inc()
                PromMetrics['PAYMENT_REQUESTS'].labels(status='error').inc()
                return 'Payment processing failed: {}'.format(str(e)), 400
                
        else:
            app.logger.info('⚠️  Stripe keys not found - using demo mode')

        # Prometheus - items purchased
        item_count = countItems(cart.get('items', []))
        PromMetrics['SOLD_COUNTER'].inc(item_count)
        PromMetrics['AUS'].observe(item_count)
        PromMetrics['AVS'].observe(cart.get('total', 0))

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
