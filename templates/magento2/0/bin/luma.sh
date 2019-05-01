#!/usr/bin/env bash

composer global require hirak/prestissimo
/usr/local/bin/magento-installer
su www-data -s $MAGENTO_ROOT/bin/magento deploy:mode:set $MAGENTO_RUN_MODE