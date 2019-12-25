# Stage #1 - Get node and build
FROM node AS node_package
RUN ls -ltr
RUN mkdir -p /opt/app/hl
WORKDIR /opt/app/hl
COPY  package* ./
RUN npm install

# Stage #2 - Copy data and run
FROM node:alpine
ENV APP_PATH=/opt/app/hl
RUN apk add bash
RUN mkdir -p /opt/app/hl/
WORKDIR /opt/app/hl
COPY . .
COPY --from=0 /opt/app/hl/node_modules ./node_modules
RUN ls -ltr .
EXPOSE 3000
ENTRYPOINT ${APP_PATH}/scripts/startService.sh
