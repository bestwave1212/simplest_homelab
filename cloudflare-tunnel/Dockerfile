FROM ghcr.io/cloudflare/cloudflared:latest

WORKDIR /app

COPY config.json /app/config.json

RUN mkdir -p /var/run/cloudflared && chmod 777 /var/run/cloudflared

EXPOSE 80 443

CMD ["run", "--no-autoupdate", "--config", "/app/config.json"]
