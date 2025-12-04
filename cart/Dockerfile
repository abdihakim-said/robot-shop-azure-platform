FROM node:14-bullseye-slim

ENV INSTANA_AUTO_PROFILE true

EXPOSE 8080

WORKDIR /opt/server

# Update Kerberos packages to fix CVE-2024-37371
RUN apt-get update && \
    apt-get upgrade -y libgssapi-krb5-2 libk5crypto3 libkrb5-3 libkrb5support0 && \
    rm -rf /var/lib/apt/lists/*

# Update npm to latest version to fix CVE-2025-7783 in npm's form-data dependency
RUN npm install -g npm@latest

COPY package.json /opt/server/

RUN npm install

COPY server.js /opt/server/

CMD ["node", "server.js"]

