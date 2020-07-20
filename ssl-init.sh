#!/bin/bash

# Source Environment Variables
source .env

# Fetch the variables you need
domains=($DOMAIN_NAME www.$DOMAIN_NAME)
rsa_key_size=$RSA_KEY_SIZE
data_path=$DATA_PATH
email=$EMAIL
staging=$STAGING

# Make sure docker compose is installed
if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

# Check for existing ssl certificates
if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

# Create Dummy Certificates
echo "### Creating dummy certificate for $domains ..."
path="/etc/letsencrypt/live/$domains"
mkdir -p "$data_path/conf/live/$domains"
docker-compose run -f docker-compose-ssl-init.yml --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:1024 -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo

# Start Nginx
echo "### Starting nginx ..."
docker-compose -f docker-compose-ssl-init.yml up --force-recreate -d nginx
echo

# Delete Dummy Certificates
echo "### Deleting dummy certificate for $domains ..."
docker-compose -f docker-compose-ssl-init.yml run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo

# Request New Certificates
echo "### Requesting Let's Encrypt certificate for $domains ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker-compose -f docker-compose-ssl-init.yml run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot
echo

# Shut everyting down
echo "### Shutting Server Down ..."
docker-compose -f docker-compose-ssl-init.yml down
