# Estágio 1: Build do App Flutter
FROM cirrusci/flutter:stable as build

WORKDIR /app

COPY pubspec.yaml ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# Estágio 2: Servidor Web
FROM nginx:stable-alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# Copia uma configuração customizada do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf
