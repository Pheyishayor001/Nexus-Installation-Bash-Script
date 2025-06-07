#!/bin/bash

# ==== CONFIGURATION ====
JAVA_PACKAGE="java-1.8.0-openjdk"
NEXUS_VERSION="3.80.0-06"
NEXUS_NAME="nexus-${NEXUS_VERSION}"
NEXUS_TAR="${NEXUS_NAME}-unix.tar.gz"
NEXUS_URL="https://download.sonatype.com/nexus/3/${NEXUS_TAR}"
NEXUS_DIR="/opt/nexus"
NEXUS_USER="nexus"
NEXUS_GROUP="nexus"
NEXUS_HOME="/home/${NEXUS_USER}"
SONATYPE_WORK_DIR="/opt/sonatype-work"
SERVICE_FILE="/etc/systemd/system/nexus.service"

# ==== FUNCTIONS ====
function fail_if_error {
    "$@" || { echo "Command failed: $*"; exit 1; }
}

echo "Updating system packages"
fail_if_error sudo yum update -y

echo "Checking Java installation"
if command -v java &> /dev/null; then
    echo "Java is already installed. Skipping."
else
    echo "Installing Java: ${JAVA_PACKAGE}"
    fail_if_error sudo yum install -y "$JAVA_PACKAGE"
fi

echo "Verifying Java installation"
fail_if_error java -version

# ==== INSTALL NEXUS ====
if [ -d "$NEXUS_DIR" ]; then
    echo "Nexus already exists at $NEXUS_DIR. Skipping download and extraction."
else
    echo "Downloading Nexus from $NEXUS_URL"
    fail_if_error wget "$NEXUS_URL"

    echo "Extracting Nexus archive"
    fail_if_error sudo tar -xzf "$NEXUS_TAR"

    echo "Moving Nexus to $NEXUS_DIR"
    fail_if_error sudo mv "$NEXUS_NAME" "$NEXUS_DIR"

    echo "Cleaning up archive"
    fail_if_error rm -f "$NEXUS_TAR"
fi

# ==== CREATE USER AND GROUP ====
if ! getent group "$NEXUS_GROUP" > /dev/null; then
    echo "Creating group: $NEXUS_GROUP"
    fail_if_error sudo groupadd "$NEXUS_GROUP"
else
    echo "Group $NEXUS_GROUP already exists"
fi

if ! id "$NEXUS_USER" > /dev/null 2>&1; then
    echo "Creating user: $NEXUS_USER"
    fail_if_error sudo useradd --system --no-create-home -g "$NEXUS_GROUP" "$NEXUS_USER"
else
    echo "User $NEXUS_USER already exists"
fi

# ==== CREATE NEXUS HOME IF MISSING ====
if [ ! -d "$NEXUS_HOME" ]; then
    echo "Creating home directory for $NEXUS_USER"
    fail_if_error sudo mkdir -p "$NEXUS_HOME"
    fail_if_error sudo chown "$NEXUS_USER:$NEXUS_GROUP" "$NEXUS_HOME"
fi

# ==== SET PERMISSIONS ====
echo "Setting permissions for Nexus directories"
fail_if_error sudo chown -R "$NEXUS_USER:$NEXUS_GROUP" "$NEXUS_DIR"
[ -d "$SONATYPE_WORK_DIR" ] || fail_if_error sudo mkdir -p "$SONATYPE_WORK_DIR"
fail_if_error sudo chown -R "$NEXUS_USER:$NEXUS_GROUP" "$SONATYPE_WORK_DIR"

# ==== CONFIGURE NEXUS ====
echo 'run_as_user="nexus"' | sudo tee "$NEXUS_DIR/bin/nexus.rc" > /dev/null

# ==== CREATE SYSTEMD SERVICE ====
echo "Creating systemd service at $SERVICE_FILE"
cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
User=${NEXUS_USER}
Group=${NEXUS_GROUP}
ExecStart=${NEXUS_DIR}/bin/nexus start
ExecStop=${NEXUS_DIR}/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# ==== ENABLE AND START SERVICE ====
echo "Making Nexus start script executable"
fail_if_error sudo chmod +x "$NEXUS_DIR/bin/nexus"

echo "Enabling and starting Nexus service"
fail_if_error sudo systemctl daemon-reexec
fail_if_error sudo systemctl enable nexus
fail_if_error sudo systemctl start nexus

echo "Checking Nexus service status"
sudo systemctl status nexus --no-pager

echo "✅ Nexus ${NEXUS_VERSION} installation completed successfully!"
