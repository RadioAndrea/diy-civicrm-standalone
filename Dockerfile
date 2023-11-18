FROM php:8.1-apache
LABEL authors="RadioAndrea@github.com"

# Install requirements for php modules
RUN apt update ; apt install -y git libcurl4-openssl-dev libxml2-dev libonig-dev libzip-dev libpng-dev

# Install PHP Composer (not to be confused with compose)
# Use their direct installation because apt install does not work well with the php container
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install civicrm required modules, soap is optional but included for completeness
RUN docker-php-ext-install bcmath curl dom mbstring zip intl fileinfo soap gd

# Create user to run and install civic so that we don't have to run as root
# Then ensure permissions in the web directory allow us to modify the files
# Also setting the sticky bit so that all child files/directories inherit perms
RUN groupadd -r civic ; useradd -m -r -g civic civic ; usermod -a -G www-data civic
RUN mkdir /var/www/civic ; chown -R civic:www-data /var/www ; chmod -R 775 /var/www ; chmod -R a+w /var/www/

# Switch to non-root user
USER civic

# Install civicrm according to https://docs.civicrm.org/installation/en/latest/standalone/
RUN git clone https://github.com/civicrm/civicrm-standalone  /var/www/civic
WORKDIR /var/www/civic
RUN composer install

# Share volume so civicrm can be configured/modified and web files can be added
volume /var/www

# Restart apache2 when we start up to make sure the latest changes are showing (maybe not needed)
ENTRYPOINT ["apache2ctl restart"]