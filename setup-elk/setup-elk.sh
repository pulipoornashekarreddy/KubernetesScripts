#!/bin/bash

# chmod +x setup-elk.sh
# sudo bash setup-elk.sh

echo "Updating system..."
sudo apt update -y

echo "Installing Docker..."
sudo apt install -y docker.io

echo "Starting Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Creating ELK network..."
sudo docker network create elk || true

echo "Creating Elasticsearch data directory..."
sudo mkdir -p /opt/elasticsearch/data
sudo chmod 777 /opt/elasticsearch/data

echo "Running Elasticsearch..."
docker run -d \
  --name elasticsearch \
  --restart unless-stopped \
  --net elk \
  -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=true" \
  -e "ELASTIC_PASSWORD=PrimaryElasticPassword123,,." \
  -e "ES_JAVA_OPTS=-Xms3g -Xmx3g" \
  -v /opt/elasticsearch/data:/usr/share/elasticsearch/data \
  docker.elastic.co/elasticsearch/elasticsearch:8.13.4

# To get kibana_system password
# sudo docker exec -it elasticsearch bin/elasticsearch-reset-password -u kibana_system

echo "Running Kibana..."
docker run -d \
  --name kibana \
  --restart unless-stopped \
  --net elk \
  -p 5601:5601 \
  -e SERVER_HOST=0.0.0.0 \
  -e ELASTICSEARCH_HOSTS=http://elasticsearch:9200 \
  -e ELASTICSEARCH_USERNAME=kibana_system \
  -e ELASTICSEARCH_PASSWORD=E=7K7RxqmnM_PhLo*80V \
  docker.elastic.co/kibana/kibana:8.13.4

echo "Waiting 40 seconds for Elasticsearch to start..."
sleep 40

echo "Testing Elasticsearch..."
curl -u elastic:PrimaryElasticPassword123,,. -X GET "http://localhost:9200/_cluster/health?pretty"

echo "Creating Filebeat role in Elasticsearch..."
curl -u elastic:PrimaryElasticPassword123,,. -X PUT "http://localhost:9200/_security/role/filebeat_writer" \
-H "Content-Type: application/json" -d '
{
  "cluster": ["monitor","read_ilm","manage_ilm"],
  "indices": [
    {
      "names": ["filebeat-*"],
      "privileges": ["create_index","create","write","auto_configure"]
    }
  ]
}'

echo "Creating Filebeat user in Elasticsearch..."
curl -u elastic:PrimaryElasticPassword123,,. -X POST "http://localhost:9200/_security/user/filebeat_user" \
-H "Content-Type: application/json" -d '
{
  "password" : "PrimaryFilebeatPasswordUserElastic123,,.",
  "roles" : [ "filebeat_writer" ],
  "full_name" : "Filebeat Service Account"
}'

echo "Creating Kibana role in Elasticsearch..."
curl -u elastic:PrimaryElasticPassword123,,. -X POST "http://localhost:9200/_security/role/log_reader" \
-H "Content-Type: application/json" -d '
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["filebeat-*"],
      "privileges": ["read","view_index_metadata"]
    },
    {
      "names": [".kibana*", ".kibana_task_manager*"],
      "privileges": ["read","write","view_index_metadata"]
    }
  ],
  "applications": [
    {
      "application": "kibana-.kibana",
      "privileges": ["all"],
      "resources": ["*"]
    }
  ]
}'

echo "Creating Kibana role in Elasticsearch..."
curl -u elastic:PrimaryElasticPassword123,,. -X POST "http://localhost:9200/_security/role/log_reader_beta" \
-H "Content-Type: application/json" -d '
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["filebeat-*"],
      "privileges": ["read","view_index_metadata"],
      "query": {
        "term": {
          "environment": "in-beta"
        }
      }
    }
  ],
  "applications": [
    {
      "application": "kibana-.kibana",
      "privileges": ["read"],
      "resources": ["*"]
    }
  ]
}'

curl -u elastic:PrimaryElasticPassword123,,. -X POST "http://localhost:9200/_security/role/log_reader_prod" \
-H "Content-Type: application/json" -d '
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["filebeat-*"],
      "privileges": ["read","view_index_metadata"],
      "query": {
        "term": {
          "environment": "in-prod"
        }
      }
    }
  ],
  "applications": [
    {
      "application": "kibana-.kibana",
      "privileges": ["read"],
      "resources": ["*"]
    }
  ]
}'

# curl -u elastic:PrimaryElasticPassword123,,. -X POST "http://localhost:9200/_security/user/kibana_user" \
# -H "Content-Type: application/json" -d '
# {
#   "password" : "PrimaryKibanaPassword123,,.",
#   "roles" : [ "log_reader_beta", "log_reader_prod" ],
#   "full_name" : "Kibana Read Only User"
# }'

# curl -u elastic:PrimaryElasticPassword123,,. -X POST "http://localhost:9200/_security/user/kibana_user" \
# -H "Content-Type: application/json" -d '
# {
#   "password" : "IndianBillng",
#   "roles" : [ "log_reader" ],
#   "full_name" : "Kibana Read Only User"
# }'

curl -u elastic:PrimaryElasticPassword123,,. -X POST "http://localhost:9200/_security/user/monisha" \
-H "Content-Type: application/json" -d '
{
  "password" : "InternMonisha",
  "roles" : [ "log_reader" ],
  "full_name" : "Kibana Read Only User"
}'


echo ""
echo "========================================"
echo "ELK setup completed!"
echo "Elasticsearch: http://YOUR_SERVER_IP:9200"
echo "Kibana:        http://YOUR_SERVER_IP:5601"
echo "========================================"