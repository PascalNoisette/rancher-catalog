#!/usr/bin/env bash

echo "# `date --iso=minute` Composer setup"
[ ! -z "${COMPOSER_GITHUB_TOKEN}" ] && composer config --global github-oauth.github.com $COMPOSER_GITHUB_TOKEN
[ ! -z "${COMPOSER_MAGENTO_USERNAME}" ] && composer config --global http-basic.repo.magento.com $COMPOSER_MAGENTO_USERNAME $COMPOSER_MAGENTO_PASSWORD
echo $M2SETUP_EDITION
[ -z "${M2SETUP_EDITION}" ] && echo "Please select magento edition" && exit -1
composer global require hirak/prestissimo
mkdir -p $MAGENTO_ROOT
COMPOSER_PROJECT=magento/project-$M2SETUP_EDITION-edition
echo $COMPOSER_PROJECT=$M2SETUP_VERSION
composer create-project \
        --repository-url=https://repo.magento.com/ \
        $COMPOSER_PROJECT=$M2SETUP_VERSION \
        --no-interaction \
        $MAGENTO_ROOT




cd $MAGENTO_ROOT
composer require smile/elasticsuite-for-retailer
composer suggest --no-dev | grep "magento/" | grep "sample-data" | xargs -i echo {}=^100.3 | xargs -t composer require


echo "Install Magento"


INSTALL_COMMAND="php $MAGENTO_ROOT/bin/magento setup:install \
    --db-host=mydb \
    --db-name=$M2SETUP_DB_NAME \
    --db-user=$M2SETUP_DB_USER \
    --db-password=$M2SETUP_DB_PASSWORD \
    --admin-firstname=admin \
    --admin-lastname=admin \
    --base-url=$M2SETUP_BASE_URL \
    --admin-email=$M2SETUP_ADMIN_EMAIL \
    --admin-user=admin \
    --backend-frontname=admin \
    --admin-password=$M2SETUP_ADMIN_PASSWORD \
    --cleanup-database \
    --session-save=redis \
    --session-save-redis-host=redis \
    --session-save-redis-port=6379 \
    --session-save-redis-db=0 \
    --cache-backend=redis \
    --cache-backend-redis-server=redis \
    --cache-backend-redis-db=_1 \
    --cache-backend-redis-port=6379 \
    --page-cache=redis \
    --page-cache-redis-server=redis \
    --page-cache-redis-db=2 \
    --page-cache-redis-port=6379
    --es-hosts=elasticsearch:9200
"


echo $INSTALL_COMMAND

$INSTALL_COMMAND

echo "Optim"

php $MAGENTO_ROOT/bin/magento config:set dev/js/minify_files 1
php $MAGENTO_ROOT/bin/magento config:set dev/css/minify_files 1
php $MAGENTO_ROOT/bin/magento config:set dev/template/minify_html 1


echo php $MAGENTO_ROOT/bin/magento deploy:mode:set $MAGENTO_RUN_MODE

php $MAGENTO_ROOT/bin/magento deploy:mode:set $MAGENTO_RUN_MODE

echo "Fixing file permissions.."

chown -R www-data:www-data $MAGENTO_ROOT



[ -f "$MAGENTO_ROOT/vendor/magento/framework/Filesystem/DriverInterface.php" ] \
  && sed -i 's/0770/0775/g' $MAGENTO_ROOT/vendor/magento/framework/Filesystem/DriverInterface.php

[ -f "$MAGENTO_ROOT/vendor/magento/framework/Filesystem/DriverInterface.php" ] \
  && sed -i 's/0660/0664/g' $MAGENTO_ROOT/vendor/magento/framework/Filesystem/DriverInterface.php

find $MAGENTO_ROOT/pub -type f -exec chmod 664 {} \;
find $MAGENTO_ROOT/pub -type d -exec chmod 775 {} \;
find $MAGENTO_ROOT/generated -type d -exec chmod g+s {} \;

echo "Installation complete"
