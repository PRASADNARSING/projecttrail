USERID=$(id -u)
R="\e[31m"  # Red for errors
G="\e[32m"  # Green for success
Y="\e[33m"  # Yellow for warnings
N="\e[0m"   # Reset color

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

# Create logs folder if it doesn't exist
if [ ! -d "$LOGS_FOLDER" ]; then
    mkdir -p "$LOGS_FOLDER"
    echo "Directory $LOGS_FOLDER created."
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N" | tee -a "$LOG_FILE_NAME"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a "$LOG_FILE_NAME"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script" | tee -a "$LOG_FILE_NAME"
        exit 1 #other than 0
    fi
}

# Script execution log
echo "Script started executing at: $TIMESTAMP" | tee -a "$LOG_FILE_NAME"

# Check if the script is run as root
CHECK_ROOT

# Database Setup for MongoDB
DB_NAME="touristPackages"
MONGO_URI="mongodb://localhost:27017/$DB_NAME"
echo "Connecting to MongoDB at $MONGO_URI" | tee -a "$LOG_FILE_NAME"

# Install MongoDB if not installed (Amazon Linux uses yum)
if ! command -v mongod &> /dev/null
then
    echo "MongoDB is not installed. Installing now..." | tee -a "$LOG_FILE_NAME"
    
    sudo tee /etc/yum.repos.d/mongodb-org-6.0.repo > /dev/null <<EOF
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF
    
    sudo yum install -y mongodb-org &>> "$LOG_FILE_NAME"
    VALIDATE $? "MongoDB installation"
    
    sudo systemctl start mongod &>> "$LOG_FILE_NAME"
    VALIDATE $? "Starting MongoDB service"
    
    sudo systemctl enable mongod &>> "$LOG_FILE_NAME"
    VALIDATE $? "Enabling MongoDB service"
else
    echo "MongoDB is already installed." | tee -a "$LOG_FILE_NAME"
fi

# Create database and collections
mongo <<EOF &>> "$LOG_FILE_NAME"
use $DB_NAME;
if (!db.getCollectionNames().includes("users")) { db.createCollection("users"); }
if (!db.getCollectionNames().includes("travelPackages")) { db.createCollection("travelPackages"); }
print("Database and collections verified.");
EOF
