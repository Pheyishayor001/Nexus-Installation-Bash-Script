**Nexus Installation Bash Script**

This repository contains a Bash script to automate the installation of **Nexus Repository Manager** on **Amazon Linux 2** (EC2) or **Ubuntu** (Vagrant VM).

**Prerequisites**

1. **Amazon EC2**:
   - **Instance Type**: t2.medium
   - **AMI**: Amazon Linux 2
2. **Vagrant VM**:
   - Ensure you have **Ubuntu** as the OS.
   - memory: 4096
   - CPU: 2

**Installation Instructions**

**Step 1: Install Git**

If Git is not installed, use the following commands based on your environment:

- **Amazon Linux 2**:

sudo yum install git -y

- **Ubuntu (Vagrant VM)**:

sudo apt update

sudo apt install git -y

**Step 2: Clone the Repository**

Clone this repository to your machine:

git clone <https://github.com/Pheyishayor001/Nexus-Installation-Bash-Script.git>

**Step 3: Navigate to the Directory**

Move into the cloned repository directory:

cd Nexus-Installation-Bash-Script/

**Step 4: Make the Script Executable**

Make the appropriate script executable based on your environment:

- **Amazon Linux 2**:

sudo chmod +x Amazon_Linux.sh

- **Ubuntu (Vagrant VM)**:

sudo chmod +x Ubuntu.sh

**Step 5: Run the Script**

Navigate back to your home directory:

cd ~

Run the installation script:

- **Amazon Linux 2**:

sudo ./Nexus-Installation-Bash-Script/Amazon_Linux.sh

- **Ubuntu (Vagrant VM)**:

sudo ./Nexus-Installation-Bash-Script/Ubuntu.sh

If you have more than one Java version installed on your Ubuntu OS, 
you will be required to select a version to use, **Select the version that 
corresponds to Java 8** as this is the version required for Nexus to run effectively.

**Post-Installation**

After installation Nexus status will be rendered. Use Ctrl C to exit the screen.
to the prompt to check nexus status is:

sudo systemctl status nexus

**To stop the Nexus:**
sudo systemctl stop nexus

**To start the Nexus again:**
rerun the script

If the service is active, ensure **port 8081** is open in your security group. You can then access Nexus in your web browser at:

- **Public IP**: YourPublicIP:8081

**NOTE**
If Nexus is active when you check the status, but it still doesn't load on your browser when you listen on port :8081, this might be because nexus is still loading in the background. 
You can run the prompt below to watch/observe the startup process:
sudo tail -f /opt/sonatype-work/nexus3/log/nexus.log

This behaviour was observed on Vagrant (Ubuntu) VMs.

