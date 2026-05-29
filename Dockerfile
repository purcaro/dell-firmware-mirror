FROM nginx:alpine
COPY nginx.docker.conf /etc/nginx/conf.d/default.conf
