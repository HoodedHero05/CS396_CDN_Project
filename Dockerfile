# Use nginx as the base image
FROM nginx:alpine

# Remove the default nginx web files
RUN rm -rf /usr/share/nginx/html/*

# Copy your project files (like index.html, audio/, etc.) into nginx's web root
COPY ./ /usr/share/nginx/html

# Expose port 80 for web traffic
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
