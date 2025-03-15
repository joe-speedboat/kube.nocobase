#!/bin/bash
# nocobase k3s installer

genpasswd() {
   local l=$1
   [ "$l" == "" ] && l=32
   tr -dc A-Za-z0-9 < /dev/urandom | head -c ${l} | xargs
}

# namespace
NAMESPACE=nocobase

# Public URL
HOST=noco.domain.tld

# Generate secrets
MYSQL_PASSWORD=$(genpasswd)
MYSQL_ROOT_PASSWORD=$(genpasswd)
APP_KEY=$(genpasswd)

# convert secrets
MYSQL_PASSWORD_BASE64=$(echo -n "$MYSQL_PASSWORD" | base64)
MYSQL_ROOT_PASSWORD_BASE64=$(echo -n "$MYSQL_ROOT_PASSWORD" | base64)
APP_KEY_BASE64=$(echo -n "$APP_KEY" | base64)

test -d runtime && echo ERROR remove ./runtime dir first
test -d ./runtime && exit 1
mkdir ./runtime
chmod 700 ./runtime
for y in *.yml
do
  cp -av $y ./runtime/$y
  sed -i "s/__NAMESPACE__/$NAMESPACE/g"                                       ./runtime/$y
  sed -i "s/__HOST__/$HOST/g"                                                 ./runtime/$y
  sed -i "s/__MYSQL_PASSWORD_BASE64__/$MYSQL_PASSWORD_BASE64/g"               ./runtime/$y
  sed -i "s/__MYSQL_ROOT_PASSWORD_BASE64__/$MYSQL_ROOT_PASSWORD_BASE64/g"     ./runtime/$y
  sed -i "s/__APP_KEY_BASE64__/$APP_KEY_BASE64/g"                             ./runtime/$y
done

echo "# current vars
NAMESPACE=$NAMESPACE
HOST=$HOST
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
APP_KEY=$APP_KEY
" > ./runtime/env.sh

ls -l ./runtime

kubectl create namespace $NAMESPACE
kubectl config set-context --current --namespace=$NAMESPACE

for y in *.yml
do
  echo runtime/$y
  kubectl apply -f runtime/$y
done

echo "all done, now login as admin:
Here are te defaults, change it now:
User name: admin@nocobase.com
Password: admin123
url: https://$HOST
"
