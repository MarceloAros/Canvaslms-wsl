#!/bin/bash

sudo mkdir -p /var/run/passenger-instreg \
  && sudo chown -R www-data:www-data /var/run/passenger-instreg \
  && sudo service postgresql start \
  && sudo service redis-server start \
  && sudo service apache2 start \
  && sudo service canvas_init start