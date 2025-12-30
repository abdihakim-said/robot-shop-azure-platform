# Deploy SRE fixes - unblocked pipeline
FROM node:18-alpine AS metrics
WORKDIR /app
COPY package.json metrics-server.js ./
RUN npm install

FROM nginx:stable

EXPOSE 8080 9090

ENV CATALOGUE_HOST=catalogue \
    USER_HOST=user \
    CART_HOST=cart \
    SHIPPING_HOST=shipping \
    PAYMENT_HOST=payment \
    RATINGS_HOST=ratings 

# Install Node.js for metrics server
RUN apt-get update && apt-get install -y nodejs npm && rm -rf /var/lib/apt/lists/*

# Copy metrics server
COPY --from=metrics /app /metrics

COPY entrypoint.sh /root/
ENTRYPOINT ["/root/entrypoint.sh"]

COPY default.conf.template /etc/nginx/conf.d/default.conf.template
COPY static /usr/share/nginx/html
