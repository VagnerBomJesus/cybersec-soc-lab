
#!/bin/bash

set -e
VERMELHO='\033[1;31m'
RESET='\033[0m'

clear
echo -e "${VERMELHO}"
cat << "EOF"

 ░▒▓███████▓▒░░▒▓██████▓▒░ ░▒▓██████▓▒░       ░▒▓█▓▒░       ░▒▓██████▓▒░░▒▓███████▓▒░       ░▒▓█▓▒░▒▓███████▓▒░ ░▒▓██████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
 ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░      ░▒▓████████▓▒░▒▓███████▓▒░       ░▒▓█▓▒░▒▓███████▓▒░░▒▓█▓▒▒▓███▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓███████▓▒░ ░▒▓██████▓▒░ ░▒▓██████▓▒░       ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░       ░▒▓█▓▒░▒▓█▓▒░       ░▒▓██████▓▒░  
                                                                                                                           
EOF
echo -e "${RESET}"
echo                                                                                                                          
# Display banner and author information
figlet VBJ
echo "Author: Vagner Bom Jesus"

# Detect VM IP for displaying service URLs
VM_IP=$(hostname -I | awk '{print $1}')
export VM_IP

############################
# 1 - Environment Setup
############################

echo "Updating system and installing dependencies..."

sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    figlet \
    jq

# Install Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker $USER
  sudo systemctl enable docker
  sudo systemctl start docker
fi

mkdir -p /opt/soc-lab && cd /opt/soc-lab

############################
# 2 - TheHive
############################

echo "Deploying TheHive..."
mkdir -p thehive && cd thehive

cat > docker-compose.yml <<'YAML'
version: '3.7'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.10
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata:/usr/share/elasticsearch/data
    ports:
      - "9201:9200"

  thehive:
    image: strangebee/thehive:5
    depends_on:
      - elasticsearch
    ports:
      - "9000:9000"
    environment:
      - "THEHIVE_elasticsearch.hosts=[\"http://elasticsearch:9201\"]"
    volumes:
      - thehive-data:/opt/thehive/data

volumes:
  esdata:
  thehive-data:
YAML

docker compose up -d
echo "TheHive deployed on $(date)" > /opt/soc-lab/thehive/INFO.txt
cd /opt/soc-lab

############################
# 3 - Shuffle (SOAR)
############################

echo "Deploying Shuffle..."
if [ ! -d shuffle ]; then
  git clone https://github.com/frikky/shuffle.git
fi
cd shuffle

# Change default Elasticsearch port to avoid conflicts
sed -i 's/9201:9200/9202:9200/' docker-compose.yml

docker compose up -d
echo "Shuffle deployed on $(date)" > /opt/soc-lab/shuffle/INFO.txt
cd /opt/soc-lab

############################
# 4 - MISP (via NUKIB)
############################

echo "Deploying MISP..."
mkdir -p misp && cd misp

curl --proto '=https' --tlsv1.2 -o docker-compose.yml https://raw.githubusercontent.com/NUKIB/misp/main/docker-compose.yml

# Adjust base URL and IP configuration
sed -i "s|MISP_BASEURL: http://:8080|MISP_BASEURL: http://$(hostname -I | awk '{print $1}' | xargs):8080|g" docker-compose.yml
sed -i 's/127.0.0.1://g' docker-compose.yml

docker compose up -d
echo "MISP deployed on $(date)" > /opt/soc-lab/misp/INFO.txt
cd /opt/soc-lab

############################
# 5 - Wazuh
############################

echo "Deploying Wazuh..."
mkdir -p wazuh && cd wazuh

curl -L https://raw.githubusercontent.com/wazuh/wazuh-docker/main/single-node/docker-compose.yml -o docker-compose.yml

# Change dashboard port to avoid conflicts
sed -i 's/443:5601/8443:5601/' docker-compose.yml

docker compose up -d
echo "Wazuh deployed on $(date)" > /opt/soc-lab/wazuh/INFO.txt
cd /opt/soc-lab

############################
# 6 - Demo Data
############################

echo "Creating demo data..."

# Wait for TheHive API
until curl -sf http://localhost:9000/api/info >/dev/null; do
  echo "Waiting for TheHive..."
  sleep 10
done
TH_TOKEN=$(curl -s -X POST -H "Content-Type: application/json" \
  -d '{"user":"admin@thehive.local","password":"secret"}' \
  http://localhost:9000/api/login | jq -r '.token')
curl -s -X POST -H "Authorization: Bearer ${TH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"Demo Case\",\"description\":\"Generated on $(date +%Y-%m-%d)\",\"severity\":1,\"tlp\":2}" \
  http://localhost:9000/api/case > /dev/null

# Wait for MISP API
until curl -sf http://localhost:8080 >/dev/null; do
  echo "Waiting for MISP..."
  sleep 10
done
MISP_KEY=$(docker compose -f misp/docker-compose.yml exec -T mysql \
  mysql -u misp -ppassword misp -N -e "select authkey from users where id=1;")
curl -s -H "Authorization: ${MISP_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"Event\":{\"info\":\"Demo event\",\"date\":\"$(date +%Y-%m-%d)\",\"distribution\":0,\"analysis\":0,\"threat_level_id\":1}}" \
  http://localhost:8080/events > /dev/null

############################
# Done
############################

echo "SOC lab deployed successfully!"
echo ""
echo "Access URLs:" 
echo "  - TheHive: http://${VM_IP}:9000 (admin@thehive.local / secret)"
echo "  - Shuffle: http://${VM_IP}:3001"
echo "  - MISP: http://${VM_IP}:8080 (admin@admin.test / admin)"
echo "  - Wazuh Dashboard: https://${VM_IP}:8443 (default credentials)"
echo ""
echo "Please change default passwords after first login."
