echo "Running certbot on " `date`
docker run -p 80:80 --rm --name certbot-certbot -v "/var/nextcloud/certbot/config/:/etc/letsencrypt" -v "/var/nextcloud/certbot/data:/var/lib/letsencrypt" certbot/certbot renew 
docker exec nextcloud-nginx nginx -s reload
