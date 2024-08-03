#!/usr/bin/env bash

function get_config_value() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: get_config_value <config_file_path> <key>"
    return 1
  fi

  value=$(grep -E "^$2=" "$1" | cut -d '=' -f 2)

  if [ -z "$value" ]; then
    echo "Error: Key '$2' not found in config file '$1'"
    return 1
  fi

  echo "$value"
  return 0
}

echo "Welcome to devenv!"
echo "A simple development environment for HTTP-based development"

mkdir -p /cert

if [ ! -f /cert/privkey.pem ] || [ ! -f /cert/fullchain.pem ]  ; then
    echo "[SSL] Generating new certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /cert/privkey.pem -out /cert/fullchain.pem -subj "/CN=localhost"
    echo "[SSL] Certificate generated!"
    echo "[SSL] Please install the certificate in your operating system to avoid security warnings"
fi

for file in /conf/services/*; do
  if [[ -f "$file" ]]; then
      filename=$(basename "$file")
      echo "$filename"
      cp /app/template.conf /etc/nginx/conf.d/$filename.conf
      port=$(get_config_value "$file" "port")
      sed -i "s/<<PORT>>/$port/g" /etc/nginx/conf.d/$filename.conf
      sed -i "s/<<HOST>>/$filename/g" /etc/nginx/conf.d/$filename.conf
    fi
done

echo "[SSL] Starting nginx..."
/usr/sbin/nginx -g "daemon off;" | tee