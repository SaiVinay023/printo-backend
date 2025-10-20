# Use official PHP 8 image with FPM support
FROM php:8.2-fpm

# Set working directory inside the container
WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Install PHP extensions required by Laravel
RUN docker-php-ext-install pdo_mysql mbstring bcmath gd

# Install Composer globally
COPY --from=composer:2.7.2 /usr/bin/composer /usr/bin/composer

# Copy application code to container
COPY . /var/www

# Change ownership of application code
RUN chown -R www-data:www-data /var/www

# Expose port for Laravel's built-in server (default is 8000, Render expects 10000)
EXPOSE 10000

# Set environment variables for production (optional)
ENV APP_ENV=production

# Start Laravel using its built-in server for container environments
CMD php artisan serve --host=0.0.0.0 --port=10000
