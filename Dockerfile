FROM php:8.2-cli AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libpq-dev \
    libzip-dev \
    zip \
    && docker-php-ext-install pdo pdo_pgsql zip bcmath pcntl

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

# Install dependencies (no dev)
RUN composer install --no-dev --optimize-autoloader

FROM php:8.2-cli AS runtime

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libpq-dev \
    libzip-dev \
    zip \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql zip bcmath pcntl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Create non-root user
RUN useradd -u 10001 -m appuser

COPY --from=builder /var/www/html /var/www/html

# Permissions
RUN chown -R appuser:appuser storage bootstrap/cache

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER appuser

CMD ["/usr/local/bin/docker-entrypoint.sh"]
