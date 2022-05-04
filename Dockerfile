# Stage #1 - Get node and build
FROM node AS node_package
RUN ls -ltr
RUN mkdir -p /opt/app/hl
WORKDIR /opt/app/hl
COPY  . .

# Stage #2 - Copy data and run
FROM node:alpine
ENV APP_PATH=/opt/app/hl
RUN apk add bash
RUN mkdir -p /opt/app/hl/
WORKDIR /opt/app/hl
COPY . .
RUN npm install reactstrap --legacy-peer-deps
RUN npm run build

# COPY --from=0 /opt/app/hl/node_modules ./node_modules
RUN ls -ltr .
ENV NODE_OPTIONS=--max_old_space_size=4096
EXPOSE 3001
ENTRYPOINT ${APP_PATH}/scripts/startService.sh
