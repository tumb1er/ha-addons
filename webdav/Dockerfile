ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

RUN mkdir -p /data/shared/.tmp
VOLUME /data/shared/.tmp

RUN apk update && \
    apk add --no-cache nginx nginx-mod-http-dav-ext && \
    nginx -V

COPY default.conf /etc/nginx/http.d/

RUN sed -i -e 's/user nginx;/user root;/g' /etc/nginx/nginx.conf
RUN nginx -t

CMD ["nginx", "-g", "daemon off;"]
