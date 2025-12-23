# Test automatic ArgoCD image updates
# Build
#
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /opt/shipping

COPY pom.xml /opt/shipping/
RUN mvn dependency:resolve
COPY src /opt/shipping/src/
RUN mvn package

#
# Run
#
FROM eclipse-temurin:17-jre

EXPOSE 8080

WORKDIR /opt/shipping

ENV CART_ENDPOINT=cart:8080
ENV DB_HOST=mysql

COPY --from=build /opt/shipping/target/shipping-1.0.jar shipping.jar

CMD [ "java", "-Xmn256m", "-Xmx768m", "--add-opens=java.base/java.io=ALL-UNNAMED", "-jar", "shipping.jar" ]
