ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

RUN apk update && \
    apk add nginx && \
    nginx -V

COPY ./dav.conf /etc/nginx/conf.d/

CMD ["nginx", "-g", "daemon off;"]
