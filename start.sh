#!/usr/bin/env bash
set -e

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

if [ ! -f /cert/devenv.key ] || [ ! -f /cert/devenv.crt ] || [ ! -f /cert/devenv.csr ] || [ ! -f /cert/devenv-cert.csr ] || [ ! -f /cert/devenv-cert.crt ] ; then
    echo "[SSL] Generating CA Key"
    openssl genrsa -aes256 -passout pass:devenv -out devenv.key 4096
    echo "[SSL] Generating CA Certificate"
    openssl req -x509 -new -nodes -key /cert/devenv.key -sha256 -days 1826 -out /cert/devenv.crt -subj '/CN=devenv Root CA/C=DE/ST=Saxony/L=Dresden/O=devenv'
    openssl req -new -nodes -out /cert/devenv-cert.csr -newkey rsa:4096 -keyout /cert/devenv-cert.key -subj '/CN=devenv Root CA/C=DE/ST=Saxony/L=Dresden/O=devenv'
    echo "[SSL] Generating new certificate..."
    openssl x509 -req -in /cert/devenv-cert.csr -CA /cert/devenv.crt -CAkey /cert/devenv.key -CAcreateserial -out /cert/devenv-cert.crt -days 730 -sha256 -extfile /app/domain.v3.ext
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
      sed -i "s/<<DOMAIN>>/$filename/g" /etc/nginx/conf.d/$filename.conf
    fi
done

echo "[SSL] Starting nginx..."
/usr/sbin/nginx -g "daemon off;" | tee