# Dockerfile
FROM php:7.3-apache

EXPOSE 80
WORKDIR /itop

RUN apt-get update -qy && apt-get install -y --no-install-recommends \
    graphviz \
    libicu-dev \
    libjpeg-dev \
    libldap2-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    mariadb-client \
    zip \
    zlib1g \
    zlib1g-dev \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    apt-get clean && \
    mkdir /phpsessions && chown www-data /phpsessions && chmod 700 /phpsessions && \
    docker-php-ext-install -j$(nproc) opcache pdo_mysql gd mysqli soap ldap zip && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP extensions
COPY conf/php.ini /usr/local/etc/php/conf.d/itop.ini

# Apache
# ADD errors /errors
COPY conf/vhost.conf /etc/apache2/sites-available/000-default.conf
COPY conf/apache.conf /etc/apache2/conf-available/z-itop.conf
RUN a2enmod rewrite remoteip && a2enconf z-itop

# This is the path to the Persistent Volume
VOLUME ["/itop"]

# Add a specific initialisation file
# some actions are done at every continer start (links rebuild in /itopsrc)
# Other actions are only done if the Image has changed
COPY misc/itop-data-init2.bash /usr/local/bin/itop-data-init2.bash
RUN chmod +x /usr/local/bin/itop-data-init2.bash

# Copy iTop files in the image
COPY itopsrc /itopsrc
# Select between the two following lines to build an images with the core extensions only
# or the full extension set
COPY extensions-core /itopsrc/extensions
#COPY extensions-full /itopsrc/extensions
RUN mv /itopsrc/data /itopsrc/datasrc && mv /itopsrc/log /itopsrc/logsrc && \
    chmod -R a-w /itopsrc && chown -R root:root /itopsrc 
# Generate e timestamp file in the image. This file is here to detect 
# any image changes at start
RUN date "+%Y-%m-%d--%H-%M-%S" >/build.manifest

# Add two LABELS in the image : build date and Maintainer
# To set the build date, the image must be built with this these options :
# docker build . --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -t itop....
ARG BUILD_DATE
LABEL maintainer="my.name@my.company.com"
LABEL org.label-schema.build_date=$BUILD_DATE

# This is the startup command in the container
CMD ["/usr/local/bin/itop-data-init2.bash"]
