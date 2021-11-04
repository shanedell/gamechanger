#!/usr/bin/env bash
set -o nounset
set -o errexit

SCRIPT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_DIR="$(cd -- "${SCRIPT_DIR}/../" &> /dev/null && pwd)"
DEPLOY_CONF="${SCRIPT_DIR}/deploy.conf.sh"

source "$DEPLOY_CONF"

function main() {
  # start up base services
  compose_wrapper up -d -- postgres redis neo4j elasticsearch kibana s3-server

  # wait until base services are up
  compose_wrapper run -- _s3_server_wait_until_ready
  compose_wrapper run -- _redis_wait_until_ready
  compose_wrapper run -- _postgres_wait_until_ready

  # config base services
  compose_wrapper run -- _postgres_config_step_1_setup_web_schema
  compose_wrapper run -- _postgres_config_step_2_setup_data_schema
  
  # start up remaining services
  compose_wrapper up -d -- web gamechanger-ml web
  
  # wait until remaining services are up
  compose_wrapper run -- _web_wait_until_ready
  compose_wrapper run -- _gamechanger_ml_wait_until_ready
}

main