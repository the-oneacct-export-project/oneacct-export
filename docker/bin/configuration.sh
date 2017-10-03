function configure_oneacct-export {
  export ONEACCT_NUM_OF_VMS_PER_FILE="${ONEACCT_NUM_OF_VMS_PER_FILE:-500}"
  export ONEACCT_SITE_NAME="${ONEACCT_SITE_NAME:-Undefined}"
  export ONEACCT_CLOUD_TYPE="${ONEACCT_CLOUD_TYPE:-OpenNebula}"
  export ONEACCT_ENDPOINT="${ONEACCT_ENDPOINT:-https://occi.localhost.com:11443/}"
  export ONEACCT_REDIS_NAMESPACE="${ONEACCT_REDIS_NAMESPACE:-oneacct_export}"
  export ONEACCT_REDIS_URL="${ONEACCT_REDIS_URL:-redis://localhost:6379}"
  export ONEACCT_SIDEKIQ_QUEUE="${ONEACCT_SIDEKIQ_QUEUE:-oneacct_export}"

  envsubst < /oneacct-export/config/conf.yml > /var/lib/apel/.oneacct-export/conf.yml
}
