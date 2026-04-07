# Stage 1: Build the Flutter web application
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Set working directory
WORKDIR /app

# Copy the dependencies file
COPY pubspec.yaml pubspec.lock ./

# Fetch dependencies
RUN flutter pub get

# Copy the entire project
COPY . .

# Build the web project
RUN flutter build web --release --base-href /

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the build output to Nginx's serving directory
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy our custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
