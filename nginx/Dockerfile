FROM --platform=linux/x86_64 nginx:latest
# for health check
RUN apt-get update && apt-get install -y curl
COPY nginx.conf /etc/nginx/nginx.conf
CMD ["/usr/sbin/nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
EXPOSE 80
