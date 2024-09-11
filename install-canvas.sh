#!/bin/bash

set -x

# Check if exactly two parameters have been passes
if [ $# -ne 2 ]; then
  echo "Usage: $0 user_name user_password"
  exit 1
fi

# Asignar parámetros a variables
user_name=$1
user_password=$2

canvas_dir_name="canvas-lms"
canvas_sys_dir="/var/$canvas_dir_name"

# Do not change of branch. I use temporal main branch
# && git checkout prod \

YELLOW_ON_PURPLE='\033[1;33;45m'
NC='\033[0m' # Sin color (reset)

echo -e "${YELLOW_ON_PURPLE}Updating package lists...${NC}" \
  && sudo apt update \
  && echo -e "${YELLOW_ON_PURPLE}Upgrading installed packages...${NC}" \
  && sudo apt upgrade -y \
  && echo -e "${YELLOW_ON_PURPLE}Installing required packages...${NC}" \
  && sudo apt-get install postgresql-14 git-core software-properties-common libyaml-dev cmdtest -y \
  && echo -e "${YELLOW_ON_PURPLE}Restarting PostgreSQL...${NC}" \
  && sudo service postgresql restart \
  && echo -e "${YELLOW_ON_PURPLE}Creating PostgreSQL user...${NC}" \
  && sudo -u postgres psql -c "CREATE USER $user_name WITH PASSWORD '$user_password' NOSUPERUSER NOCREATEDB NOCREATEROLE;" \
  && echo -e "${YELLOW_ON_PURPLE}Creating canvas_production database...${NC}" \
  && sudo -u postgres createdb canvas_production --owner=$user_name \
  && echo -e "${YELLOW_ON_PURPLE}Creating canvas_development database...${NC}" \
  && sudo -u postgres createdb canvas_development --owner=$user_name \
  && echo -e "${YELLOW_ON_PURPLE}Altering PostgreSQL user to SUPERUSER...${NC}" \
  && sudo -u postgres psql -c "ALTER USER $user_name WITH SUPERUSER;" \
  && echo -e "${YELLOW_ON_PURPLE}Adding Ruby repository...${NC}" \
  && sudo add-apt-repository -y ppa:instructure/ruby \
  && echo -e "${YELLOW_ON_PURPLE}Updating package lists again...${NC}" \
  && sudo apt-get update \
  && echo -e "${YELLOW_ON_PURPLE}Installing Ruby and other dependencies...${NC}" \
  && sudo apt-get install -y ruby3.1 ruby3.1-dev zlib1g-dev libxml2-dev \
                            libsqlite3-dev postgresql libpq-dev \
                            libxmlsec1-dev libyaml-dev libidn11-dev curl make g++ \
  && echo -e "${YELLOW_ON_PURPLE}Setting up Node.js...${NC}" \
  && curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash - \
  && echo -e "${YELLOW_ON_PURPLE}Installing Node.js and npm...${NC}" \
  && sudo apt-get install -y nodejs \
  && sudo npm install -g npm@latest \
  && echo -e "${YELLOW_ON_PURPLE}Removing old Yarn...${NC}" \
  && sudo rm /usr/bin/yarn \
  && echo -e "${YELLOW_ON_PURPLE}Installing specific version of Yarn...${NC}" \
  && sudo npm -g install yarn@1.19.1 \
  && echo -e "${YELLOW_ON_PURPLE}Cloning Canvas LMS repository...${NC}" \
  && sudo su -c "git clone https://github.com/instructure/canvas-lms.git /home/$user_name/$canvas_dir_name \
      && cd /home/$user_name/$canvas_dir_name \
      && echo git checkout prod" $user_name \
  && echo -e "${YELLOW_ON_PURPLE}Creating system directory...${NC}" \
  && sudo mkdir -p $canvas_sys_dir \
  && echo -e "${YELLOW_ON_PURPLE}Changing ownership of system directory...${NC}" \
  && sudo chown -R $user_name $canvas_sys_dir \
  && echo -e "${YELLOW_ON_PURPLE}Changing ownership of configs directory...${NC}" \
  && sudo chown -R $user_name /home/$user_name/configs \
  && echo -e "${YELLOW_ON_PURPLE}Copying Canvas LMS to system directory...${NC}" \
  && cd /home/$user_name/$canvas_dir_name \
  && cp -av . $canvas_sys_dir \
  && echo -e "${YELLOW_ON_PURPLE}Copying configuration files...${NC}" \
  && sudo cp -f /home/$user_name/configs/canvas/*.yml $canvas_sys_dir/config/ \
  && sudo chown $user_name:www-data $canvas_sys_dir/config/ \
  && echo -e "${YELLOW_ON_PURPLE}Installing additional dependencies...${NC}" \
  && sudo apt install libyaml-dev cmdtest -y \
  && echo -e "${YELLOW_ON_PURPLE}Setting up Bundler and installing gems...${NC}" \
  && sudo su -c "sudo gem install bundler --version 2.5.10 \
      && bundle config set --local path vendor/bundle \
      && bundle install" $user_name \
  && echo -e "${YELLOW_ON_PURPLE}Updating and installing specific Ruby gems...${NC}" \
  && sudo gem update strscan \
  && sudo gem uninstall stringio \
  && sudo gem install stringio -v 3.1.1 \
  && sudo gem uninstall base64 \
  && sudo gem install base64 -v 0.2.0 \
  && echo -e "${YELLOW_ON_PURPLE}Setting up Canvas LMS...${NC}" \
  && sudo su -c "cd $canvas_sys_dir \
      && export CANVAS_LMS_ADMIN_EMAIL="admin@canvas.local" \
      && export CANVAS_LMS_ADMIN_PASSWORD="holaadios" \
      && export CANVAS_LMS_ACCOUNT_NAME="canvas" \
      && export CANVAS_LMS_STATS_COLLECTION="3" \
      && sudo apt-get install libyaml-dev; sudo apt-get install cmdtest; sudo gem install bundler --version 2.5.10; bundle config set --local path vendor/bundle; sudo gem install bundler-multilock; bundle install; sudo gem update strscan; sudo gem uninstall stringio; sudo gem install stringio -v 3.1.1; sudo gem uninstall base64; sudo gem install base64 -v 0.2.0; yarn install; mv db/migrate/20210823222355_change_immersive_reader_allowed_on_to_on.rb .; mv db/migrate/20210812210129_add_singleton_column.rb db/migrate/20111111214311_add_singleton_column.rb; yarn gulp rev; RAILS_ENV=production bundle exec rake db:initial_setup; mv 20210823222355_change_immersive_reader_allowed_on_to_on.rb db/migrate/.; RAILS_ENV=production bundle exec rake db:migrate; mkdir -p log tmp/pids public/assets app/stylesheets/brandable_css_brands; touch app/stylesheets/_brandable_variables_defaults_autogenerated.scss Gemfile.lock log/production.log; sudo chown -R $user_name config/environment.rb log tmp public/assets app/stylesheets/_brandable_variables_defaults_autogenerated.scss app/stylesheets/brandable_css_brands Gemfile.lock config.ru; RAILS_ENV=production bundle exec rake canvas:compile_assets;" $user_name \
  && echo -e "${YELLOW_ON_PURPLE}Installing Apache, Passenger, and SSL configuration...${NC}" \
  && sudo apt install -y apache2 dirmngr gnupg apt-transport-https ca-certificates curl \
  && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7 \
  && curl https://oss-binaries.phusionpassenger.com/auto-software-signing-gpg-key.txt | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/phusion.gpg >/dev/null \
  && sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger $(lsb_release -cs) main > /etc/apt/sources.list.d/passenger.list' \
  && sudo apt-get update \
  && sudo apt-get install -y libapache2-mod-passenger \
  && echo -e "${YELLOW_ON_PURPLE}Enabling Apache modules...${NC}" \
  && sudo a2enmod rewrite \
  && sudo a2enmod passenger \
  && sudo a2enmod ssl \
  && echo -e "${YELLOW_ON_PURPLE}Configuring Passenger and SSL...${NC}" \
  && sudo mkdir -p /var/run/passenger-instreg \
  && sudo chown -R $user_name:www-data /var/run/passenger-instreg \
  && sudo cp -f /home/$user_name/configs/passenger/passenger.conf /etc/apache2/mods-available/passenger.conf \
  && sudo service apache2 restart \
  && echo -e "${YELLOW_ON_PURPLE}Enabling XSendfile module...${NC}" \
  && sudo apt install libapache2-mod-xsendfile -y \
  && sudo a2enmod xsendfile \
  && echo -e "${YELLOW_ON_PURPLE}Copying SSL certificates...${NC}" \
  && sudo cp -f /home/$user_name/configs/certs/canvas.local.key /etc/ssl/private/ \
  && sudo cp -f /home/$user_name/configs/certs/canvas.local.crt /etc/ssl/certs/ \
  && sudo cp /etc/ssl/certs/canvas.local.crt /usr/local/share/ca-certificates/ \
  && sudo update-ca-certificates \
  && echo -e "${YELLOW_ON_PURPLE}Setting up Apache virtual hosts...${NC}" \
  && sudo cp -f /home/$user_name/configs/apache/canvas.local.conf /etc/apache2/sites-available/ \
  && sudo cp -f /home/$user_name/configs/apache/canvas.local-ssl.conf /etc/apache2/sites-available/ \
  && sudo a2dissite 000-default.conf \
  && sudo a2ensite canvas.local.conf \
  && sudo a2ensite canvas.local-ssl.conf \
  && echo -e "${YELLOW_ON_PURPLE}Setting permissions for Canvas LMS...${NC}" \
  && sudo su -c "cd /var/canvas-lms; current_user=$(whoami); sudo chown -R "\$current_user":"\$current_user" .; sudo find config/ -type f -exec chmod 400 {} +;" $user_name \
  && echo -e "${YELLOW_ON_PURPLE}Installing Redis and configuring services...${NC}" \
  && sudo apt-get update \
  && sudo apt-get install redis-server -y \
  && echo -e "${YELLOW_ON_PURPLE}Copying secondary configuration files...${NC}" \
  && sudo cp -f /home/$user_name/configs/canvas/second/*.yml $canvas_sys_dir/config/ \
  && sudo chown -R $user_name:www-data $canvas_sys_dir \
  && echo -e "${YELLOW_ON_PURPLE}Configuring and starting services...${NC}" \
  && sudo ln -s $canvas_sys_dir/script/canvas_init /etc/init.d/canvas_init \
  && sudo update-rc.d canvas_init defaults \
  && sudo /etc/init.d/canvas_init start \
  && sudo service apache2 restart \
  && sudo update-rc.d apache2 enable

# admin@canvas.local
# holahola
# Canvas
# 3