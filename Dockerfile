# Use official PHP 8 image with FPM support
FROM php:8.2-fpm

# Set working directory inside the container
WORKDIR /var/www

# Install system dependencies (add libpq-dev for PDO_PGSQL)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev        # Required for Postgres extension

# Install PHP extensions required by Laravel
RUN docker-php-ext-install pdo_mysql pdo_pgsql mbstring bcmath gd

# Install Composer globally (from official Composer image)
COPY --from=composer:2.7.2 /usr/bin/composer /usr/bin/composer

# Copy application code to container
COPY . /var/www

# Install PHP dependencies (CRUCIAL for Laravel start)
RUN composer install --optimize-autoloader --no-dev

# Change ownership of app code
RUN chown -R www-data:www-data /var/www

# Expose Laravel server port (10000 for Render)
EXPOSE 10000

# Set environment variables for production (optional, adjust as needed)
ENV APP_ENV=production

# Start Laravel using built-in server for container deployments
CMD php artisan serve --host=0.0.0.0 --port=10000
