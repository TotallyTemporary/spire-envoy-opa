# Install wrk
sudo apt-get install build-essential libssl-dev git -y 
git clone https://github.com/wg/wrk.git wrk 
cd wrk 
sudo make 
sudo cp wrk /usr/local/bin 


# Install nginx to return HTTP 204 on the configured port
sudo apt-get install nginx
sudo cp nginx.conf /etc/nginx/sites-available/test_conf.conf
sudo ln -s /etc/nginx/sites-available/test_conf.conf /etc/nginx/sites-enabled/test_conf.conf

