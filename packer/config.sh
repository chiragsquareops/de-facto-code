#Project Nginx Configuration

#!/bin/bash

# cd /home/app
# sudo mv /home/app/HospitalMS /var/www/HospitalMS
# sudo chown -R www-data.www-data /var/www/HospitalMS/storage
# sudo chown -R www-data.www-data /var/www/HospitalMS/bootstrap/cache
# sudo chmod -R 775 storage
# sudo chmod -R 775 bootstrap/cache
sudo mv /tmp/nginx.conf /etc/nginx/sites-available/hospital
sudo ln -s /etc/nginx/sites-available/hospital /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
