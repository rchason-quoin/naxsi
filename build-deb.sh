#!/bin/bash

# Update OS & Install deps

# if [ -f "/etc/apt/sources.list" ]; then
#   cat /etc/apt/sources.list > /tmp/sources.list.orig
#   cat /tmp/sources.list.orig | grep -v "#" | sed 's/^deb /deb-src /g' >> /etc/apt/sources.list
# fi
# apt-get -qqy update
# DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends install \
#     build-essential \
#     ca-certificates \
#     dpkg-dev \
#     gzip \
#     git \
#     libgd-dev \
#     libgeoip-dev \
#     libpcre3-dev \
#     libssl-dev \
#     libxslt1-dev \
#     nginx \
#     tar \
#     wget \
#     zlib1g-dev
# if [ -f "/etc/apt/sources.list.d/debian.sources" ]; then
#   # bookworm only.
#   echo "deb https://ftp.debian.org/debian/ bookworm contrib main non-free non-free-firmware" >> /etc/apt/sources.list.d/nginx.list
#   echo "deb-src https://ftp.debian.org/debian/ bookworm contrib main non-free non-free-firmware" >> /etc/apt/sources.list.d/nginx.list
#   apt-get -qqy update
#   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends install \
#     libperl-dev
# fi

set -exv

# Checkout needed repos

rm -rf naxsi_src/libinjection
git clone https://github.com/libinjection/libinjection.git naxsi_src/libinjection
git -C naxsi_src/libinjection checkout 51f3a96e9fcc90a6112f52ac96fd4661e7ab0a44
rm -rf deb-creator
git clone --depth=1 https://github.com/wargio/deb-creator.git
chmod 777 .
apt-get source nginx

mkdir -p deb_pkg/
DEB_PKG=$(realpath deb_pkg)
NAXSI_VERSION=$(grep "NAXSI_VERSION" naxsi_src/naxsi_const.h | cut -d ' ' -f3 | sed 's/"//g')
LIBPCRE3_VERSION=$(dpkg -s libpcre3 | grep '^Version:' | cut -d ' ' -f2 | cut -d '-' -f1)
NGINX_VERSION=$(dpkg -s nginx | grep '^Version:' | cut -d ' ' -f2 | cut -d '-' -f1)
NGINX_BUILD_OPTS=$(/usr/sbin/nginx -V 2>&1 | grep "configure arguments:" | cut -d ":" -f2- | sed -e "s#/build/nginx-[A-Za-z0-9]*/#./#g" | sed 's/--add-dynamic-module=[A-Za-z0-9\/\._-]*//g')
echo "NGINX_VERSION:    $NGINX_VERSION"
echo "NGINX_BUILD_OPTS: $NGINX_BUILD_OPTS"
# build module
cd nginx-$NGINX_VERSION
CMDLINE=$(echo ./configure $NGINX_BUILD_OPTS --add-dynamic-module=../naxsi_src/)
eval $CMDLINE
make modules
cd ..
# install files
mkdir -p "$DEB_PKG/data/usr/lib/nginx/modules/"
mkdir -p "$DEB_PKG/data/usr/share/nginx/modules-available/"
mkdir -p "$DEB_PKG/data/usr/share/naxsi/whitelists"
mkdir -p "$DEB_PKG/data/usr/share/naxsi/blocking"
install -Dm755 distros/deb/postinstall.script "$DEB_PKG/postinstall.script"
install -Dm755 distros/deb/postremove.script "$DEB_PKG/postremove.script"
install -Dm755 distros/deb/preremove.script "$DEB_PKG/preremove.script"
install -Dm644 distros/deb/control.install "$DEB_PKG/control.install"
install -Dm755 "nginx-$NGINX_VERSION/objs/ngx_http_naxsi_module.so" "$DEB_PKG/data/usr/lib/nginx/modules/ngx_http_naxsi_module.so"
install -Dm644 distros/deb/mod-http-naxsi.conf "$DEB_PKG/data/usr/share/nginx/modules-available/mod-http-naxsi.conf"
install -Dm644 distros/nginx/naxsi_block_mode.conf "$DEB_PKG/data/usr/share/naxsi/naxsi_block_mode.conf"
install -Dm644 distros/nginx/naxsi_denied_url.conf "$DEB_PKG/data/usr/share/naxsi/naxsi_denied_url.conf"
install -Dm644 distros/nginx/naxsi_learning_mode.conf "$DEB_PKG/data/usr/share/naxsi/naxsi_learning_mode.conf"
install -Dm644 naxsi_rules/naxsi_core.rules "$DEB_PKG/data/usr/share/naxsi/naxsi_core.rules"
install -Dm644 naxsi_rules/whitelists/*.rules "$DEB_PKG/data/usr/share/naxsi/whitelists"
install -Dm644 naxsi_rules/blocking/*.rules "$DEB_PKG/data/usr/share/naxsi/blocking"
# add deb details.
sed -i "s/@NGINX_VERSION@/$NGINX_VERSION/" "$DEB_PKG/control.install"
sed -i "s/@LIBPCRE3_VERSION@/$LIBPCRE3_VERSION/" "$DEB_PKG/control.install"
sed -i "s/@NAXSI_VERSION@/$NAXSI_VERSION/" "$DEB_PKG/control.install"
# build deb file
./deb-creator/deb-creator "$DEB_PKG"
