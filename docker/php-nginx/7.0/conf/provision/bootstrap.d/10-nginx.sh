#!/usr/bin/env bash

IMAGE_FAMILY=$(docker-image-info family)

go-replace --mode=line --regex --regex-backrefs \
    -s '^[\s#]*(daemon)' -r 'daemon off' \
    -s '^([ \t]*access_log)[ \t]*([^\t ;]+)(.*;)$' -r '$1 /docker.stdout $3' \
    -s '^([ \t]*error_log)[ \t]*([^\t ;]+)(.*;)$' -r '$1 /docker.stderr $3' \
    --  /etc/nginx/nginx.conf

# Enable nginx main config
ln -sf /opt/docker/etc/nginx/main.conf /etc/nginx/conf.d/10-docker.conf

rm -f \
    /etc/nginx/sites-enabled/default \
    /etc/nginx/conf.d/default.conf

if [[ "$IMAGE_FAMILY" == "RedHat" ]] || [[ "$IMAGE_FAMILY" == "Alpine" ]]; then
    ln -sf /opt/docker/etc/nginx/nginx.conf /etc/nginx/nginx.conf
fi

# Clear log dir
rm -rf /var/lib/nginx/logs
mkdir -p /var/lib/nginx/logs

# Set log to stdout/stderr
ln -sf /var/lib/nginx/logs/access.log /docker.stdout
ln -sf /var/lib/nginx/logs/error.log /docker.stderr

# Fix rights of ssl files
chown -R root:root /opt/docker/etc/nginx/ssl
chmod 0750 /opt/docker/etc/nginx/ssl
chmod 0640 /opt/docker/etc/nginx/ssl/server.crt
chmod 0640 /opt/docker/etc/nginx/ssl/server.csr
chmod 0640 /opt/docker/etc/nginx/ssl/server.key
