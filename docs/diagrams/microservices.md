# Microservices Architecture

```mermaid
graph TB
    USER[User/Browser] -->|HTTP| LB[Azure Load Balancer]
    LB -->|Port 8080| WEB[Web Service<br/>AngularJS + Nginx]

    WEB -->|REST API| CART[Cart Service<br/>Node.js]
    WEB -->|REST API| CATALOGUE[Catalogue Service<br/>Node.js]
    WEB -->|REST API| USER_SVC[User Service<br/>Node.js]
    WEB -->|REST API| PAYMENT[Payment Service<br/>Python]
    WEB -->|REST API| SHIPPING[Shipping Service<br/>Java Spring Boot]

    CART -->|Store| REDIS[(Redis<br/>Session Store)]
    CATALOGUE -->|Query| MONGO[(MongoDB<br/>Product DB)]
    USER_SVC -->|Query| MONGO
    PAYMENT -->|Queue| RABBIT[RabbitMQ<br/>Message Queue]
    SHIPPING -->|Query| MYSQL[(MySQL<br/>Orders DB)]
    
    RATINGS[Ratings Service<br/>PHP] -->|Query| MYSQL
    DISPATCH[Dispatch Service<br/>Go] -->|Consume| RABBIT

    subgraph "Frontend"
        WEB
    end

    subgraph "Business Logic"
        CART
        CATALOGUE
        USER_SVC
        PAYMENT
        SHIPPING
        RATINGS
        DISPATCH
    end

    subgraph "Data Layer"
        MONGO
        MYSQL
        REDIS
        RABBIT
    end

    style WEB fill:#3498db
    style CART fill:#2ecc71
    style CATALOGUE fill:#2ecc71
    style USER_SVC fill:#2ecc71
    style PAYMENT fill:#2ecc71
    style SHIPPING fill:#2ecc71
    style RATINGS fill:#2ecc71
    style DISPATCH fill:#2ecc71
    style MONGO fill:#e74c3c
    style MYSQL fill:#e74c3c
    style REDIS fill:#e74c3c
    style RABBIT fill:#e74c3c
```

## Service Details

### Frontend
- **Web**: AngularJS + Nginx (Port 8080)

### Stateless Services
- **Cart**: Node.js - Shopping cart management
- **Catalogue**: Node.js - Product catalog
- **User**: Node.js - User authentication
- **Payment**: Python - Payment processing
- **Shipping**: Java Spring Boot - Shipping calculations
- **Ratings**: PHP - Product ratings
- **Dispatch**: Go - Order dispatch

### Stateful Services
- **MongoDB**: Product and user data
- **MySQL**: Orders and ratings
- **Redis**: Session storage
- **RabbitMQ**: Async messaging

## Communication Patterns

- **Synchronous**: REST APIs (HTTP)
- **Asynchronous**: RabbitMQ (AMQP)
- **Data Storage**: Direct database connections

## Technology Stack

| Service | Language | Framework |
|---------|----------|-----------|
| Web | JavaScript | AngularJS |
| Cart | Node.js | Express |
| Catalogue | Node.js | Express |
| User | Node.js | Express |
| Payment | Python | Flask |
| Shipping | Java | Spring Boot |
| Ratings | PHP | - |
| Dispatch | Go | - |
