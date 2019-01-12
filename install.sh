#!/bin/bash

# Installs Sentry and all dependencies on a fresh Debian 9.
# Installation requires 4GB of RAM. If you don't have that much,
# increase the swap size. Running should be okay at 1 GB.
# To start, copy all files to the server and invoke ./install.sh.

# Error handling:
set -e
trap 'echo "Error on line $LINENO"' ERR

# Change these values!
DOMAIN=sentry.myapp.com
GMAIL_USER=john@gmail.com
GMAIL_PASSWORD=mypassword
ADMIN_EMAIL=john@gmail.com

if [ -z "$LC_ALL" ]; then
    echo 'Setting locale to avoid Perl warnings "Setting locale failed."'
    locale-gen en_US.UTF-8
    su -c "echo -e 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8' > /etc/default/locale"
    echo 'Shell restart required. Please log out and back in, then execute the script again.'
    exit
fi

apt-get update
apt-get upgrade -y

echo 'Installing docker...'
apt-get install apt-transport-https dirmngr -y
echo 'deb https://apt.dockerproject.org/repo debian-stretch main' >> /etc/apt/sources.list
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys F76221572C52609D
apt-get update
apt-get install docker-engine -y

echo 'Installing docker-compose'
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo 'Creating application user...'
useradd --system --gid docker --shell /bin/bash -m sentry

echo 'Cloning sentry-onpremise repository...'
su -c 'git clone https://github.com/getsentry/onpremise.git sentry' - sentry
su -c 'cd sentry && git checkout cd13427aa9a231b2b27c9fd14017d183cca52c1e' - sentry

echo 'Updating Sentry config to use SSL...'
sed -i 's/environment:/environment:\n    SENTRY_USE_SSL: 1/g' /home/sentry/sentry/docker-compose.yml

echo 'Updating Sentry config to use Gmail...'
sed -i "s=image: tianon/exim4=image: tianon/exim4\n    environment:\n      GMAIL_USER: ${GMAIL_USER}\n      GMAIL_PASSWORD: ${GMAIL_PASSWORD}=g" /home/sentry/sentry/docker-compose.yml

echo 'Building Sentry...'
su -c 'docker volume create --name=sentry-data' - sentry
su -c 'docker volume create --name=sentry-postgres' - sentry
su -c 'cd sentry && cp -n .env.example .env' - sentry
su -c 'cd sentry && docker-compose build' - sentry
su -c 'cd sentry && SENTRY_SECRET_KEY=`docker-compose run --rm web config generate-secret-key` && echo "SENTRY_SECRET_KEY=${SENTRY_SECRET_KEY}" > .env' - sentry
su -c 'cd sentry && docker-compose run --rm web upgrade' - sentry

echo 'Creating all necessary Docker containers...'
su -c 'cd sentry && docker-compose up -d' - sentry

echo 'Installing Lets Encrypt...'
git clone https://github.com/letsencrypt/letsencrypt

echo 'Generating SSL certificates...'
letsencrypt/letsencrypt-auto --standalone --non-interactive --force-renew --email ${ADMIN_EMAIL} --agree-tos auth -d ${DOMAIN}

echo 'Uninstalling Lets Encrypt...'
rm -rf letsencrypt

echo 'Creating Sentry log file directory...'
su -c 'mkdir -p /home/sentry/logs' - sentry

echo 'Setting up Nginx...'
apt-get install nginx -y
cp nginx-site /etc/nginx/sites-available/sentry
sed -i "s/DOMAIN/${DOMAIN}/g" /etc/nginx/sites-available/sentry
ln -s /etc/nginx/sites-available/sentry /etc/nginx/sites-enabled/sentry
rm /etc/nginx/sites-enabled/default
service nginx reload

echo 'Installing Supervisor...'
apt-get install supervisor -y

echo 'Configuring Supervisor...'
cp supervisor*.conf /etc/supervisor/conf.d/

echo 'Updating Supervisor...'
supervisorctl reread
supervisorctl update

echo "Rebooting. In a few minutes, you should be able to open https://${DOMAIN}"
reboot