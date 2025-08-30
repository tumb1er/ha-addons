ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

RUN mkdir -p /data/tmp
VOLUME /data/tmp

RUN apk update && \
    apk add nginx nginx-mod-http-dav-ext && \
    nginx -V

COPY default.conf /etc/nginx/http.d/

RUN sed -i -e 's/user nginx;/user nobody;/g' /etc/nginx/nginx.conf

RUN nginx -V
RUN nginx -t

CMD ["nginx", "-g", "daemon off;"]
