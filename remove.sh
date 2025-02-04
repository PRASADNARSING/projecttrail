# Stop MySQL and MongoDB services
sudo systemctl stop mysqld
sudo systemctl stop mongod

# Uninstall MySQL
sudo yum remove mysql-server mysql-client mysql-common mysql-libs
sudo rm -rf /etc/my.cnf /etc/my.cnf.d /var/lib/mysql /var/log/mysqld.log

# Uninstall MongoDB
sudo yum remove mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools
sudo rm -rf /var/lib/mongo /var/log/mongodb /etc/mongod.conf

# Remove logs folder
sudo rm -rf /var/log/expense-logs

# Reinstall MySQL
sudo yum install mysql-server

# Start and enable MySQL service
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Navigate to project directory
cd ~/projecttrail

# Make the script executable
chmod +x database.sh

# Run the script
sudo ./database.sh