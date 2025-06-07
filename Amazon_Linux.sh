#!/bin/bash 

echo "Updating system packages"
sudo yum update -y || { echo "Failed to update packages"; exit 1; }     

echo "Installing Java"
#wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz
if command -v java &> /dev/null; then
    echo "Java is already installed. Skipping download and setup."      
else
    echo "Java is not installed. Proceeding with download and setup."   

    # Download Java
    sudo yum install java-1.8.0-openjdk -y || { echo "Failed to install Java"; exit 1; }


    echo "Java installation completed."
fi

echo "Verifying Java installation"
java -version || { echo "Java installation verification failed"; exit 1; }

# Define the Nexus version and installation path
NEXUS_VERSION="nexus-3.80.0-06"
NEXUS_DIR="/opt/nexus"
NEXUS_TAR="${NEXUS_VERSION}-unix.tar.gz"

# Check if Nexus is already installed
if [ -d "$NEXUS_DIR" ]; then
    echo "Nexus is already installed. Skipping download and setup."
else
    echo "Nexus is not installed. Proceeding with download and setup."

    # Download Nexus
    echo "Downloading Nexus"
    sudo wget https://download.sonatype.com/nexus/3/nexus-3.45.0-01-unix.tar.gz || { echo "Failed to download Nexus"; exit 1; }

    # Update system packages
    echo "Updating system packages"
    sudo yum update -y || { echo "Failed to update packages"; exit 1; }

    # Extract Nexus and rename the directory
    echo "Extracting Nexus and renaming it"
    sudo tar -xvzf "$NEXUS_TAR" || { echo "Failed to extract Nexus archive"; exit 1; }
    sudo mv nexus-3.45.0-01 "$NEXUS_DIR" || { echo "Failed to rename Nexus directory"; exit 1; }

    # Clean up the downloaded archive
    echo "Cleaning up downloaded archive"
    rm -f "$NEXUS_TAR" || { echo "Failed to remove downloaded archive"; exit 1; }
fi

# create Nexus user and Group
echo "Creating Nexus User and Group"
sudo groupadd nexus  # Create the 'nexus' group
sudo useradd --system --no-create-home -g nexus nexus  # Create the 'nexus' user and add it to the 'nexus' group

# Set the home directory for the nexus user
NEXUS_HOME="/home/nexus"

# Check if the home directory exists, and create it if it doesn't
if [ ! -d "$NEXUS_HOME" ]; then
    echo "Creating home directory for nexus user at $NEXUS_HOME"
    sudo mkdir -p "$NEXUS_HOME" || { echo "Failed to create home directory for nexus"; exit 1; }
    sudo chown nexus:nexus "$NEXUS_HOME" || { echo "Failed to set permissions for $NEXUS_HOME"; exit 1; }
fi


# Define the Nexus user and group
NEXUS_USER="nexus"
NEXUS_GROUP="nexus"

# Check if the group already exists
if ! getent group "$NEXUS_GROUP" > /dev/null; then
    echo "Creating group: $NEXUS_GROUP"
    sudo groupadd "$NEXUS_GROUP" || { echo "Failed to create group $NEXUS_GROUP"; exit 1; }
else
    echo "Group $NEXUS_GROUP already exists. Skipping group creation."
fi

# Check if the user already exists
if ! id "$NEXUS_USER" > /dev/null 2>&1; then
    echo "Creating user: $NEXUS_USER"
    sudo useradd --system --no-create-home -g "$NEXUS_GROUP" "$NEXUS_USER" || { echo "Failed to create user $NEXUS_USER"; exit 1; }
else
    echo "User $NEXUS_USER already exists. Skipping user creation."
fi

# Setting Permissions
echo "Setting Permissions"
sudo chown -R nexus:nexus "$NEXUS_DIR" || { echo "Failed to set permissions for $NEXUS_DIR"; exit 1; }
[ -d /opt/sonatype-work ] || sudo mkdir /opt/sonatype-work
sudo chown -R nexus:nexus /opt/sonatype-work || { echo "Failed to set permissions for /opt/sonatype-work"; exit 1; }

# Configuring Nexus
echo "Configuring Nexus"
echo 'run_as_user="nexus"' | sudo tee "$NEXUS_DIR/bin/nexus.rc" > /dev/null || { echo "Failed to configure Nexus"; exit 1; }

echo "Creating a Systemd Service File for Nexus"        
echo "[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/nexus.service > /dev/null || { echo "Failed to create Nexus service file"; exit 1; } 

echo "Starting and Enabling Nexus Service"
sudo chmod +x /opt/nexus/bin/nexus
#sh /opt/nexus/bin/nexus start || { echo "Failed to start Nexus"; exit 1; }   

sudo systemctl enable nexus || { echo "Failed to enable Nexus"; exit 1; }
sudo systemctl start nexus || { echo "Failed to start Nexus"; exit 1; }       

echo "Checking Nexus status"
sudo systemctl status nexus || { echo "Failed to check Nexus status"; exit 1; }

echo "Nexus installation and setup completed successfully!"
