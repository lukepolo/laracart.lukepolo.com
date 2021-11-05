FROM node:6.14-alpine as node
RUN apk --no-cache add g++ gcc libgcc libstdc++ linux-headers make python

WORKDIR /build

COPY package*.json ./
COPY yarn.lock ./
RUN yarn

COPY . .

# Build the project
RUN npm run prod

FROM php:5.6-cli

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apt-get update
RUN apt-get install -y zlib1g-dev zip git
RUN docker-php-ext-install zip

WORKDIR /app

# Copy composer.lock and composer.json
COPY composer.lock composer.json ./

COPY . .

RUN git submodule update --init

RUN composer install

# Copy from the stage 1
COPY --from=node /build/public ./public

EXPOSE 8000
ENTRYPOINT ["php", "artisan", "serve", "--host", "0.0.0.0"]
