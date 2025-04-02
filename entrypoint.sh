#!/usr/bin/env bash
set -e

# Function to install plugins (will run as rrkts_jenkins user)
install_plugins() {
  echo "Installing required plugins..."
  
  # Create plugins directory if it doesn't exist
  mkdir -p /var/jenkins_home/plugins
  
  # Install plugins
  jenkins-plugin-cli --plugins workflow-aggregator pipeline-model-definition git
  
  echo "Plugins installation complete."
  
  # Clear cache if exists
  if [ -d "/var/jenkins_home/cache" ]; then
    echo "Clearing cache..."
    rm -rf /var/jenkins_home/cache
  fi
}

# If we're running as root, set permissions and switch to rrkts_jenkins user
if [ "$(id -u)" = "0" ]; then
  echo "Setting correct permissions as root..."
  
  # Set permissions for Jenkins home
  chown -R rrkts_jenkins:rrkts_jenkins /var/jenkins_home
  chmod -R 755 /var/jenkins_home
  
  # Ensure docker socket is accessible if present
  if [ -e /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock
  fi
  
  # Switch to rrkts_jenkins user if we're running as root
  echo "Switching to rrkts_jenkins user..."
  exec gosu rrkts_jenkins "$0" "$@"
  exit 0
fi

# From this point, we're running as rrkts_jenkins user
echo "Starting Jenkins as $(whoami)..."

# Install plugins
install_plugins

# Find the correct path to tini
TINI_PATH=""
for path in "/sbin/tini" "/usr/bin/tini" "/usr/local/bin/tini" "/bin/tini"; do
  if [ -x "$path" ]; then
    TINI_PATH="$path"
    break
  fi
done

# Start Jenkins with tini if found, or directly if not
echo "Starting Jenkins..."
if [ -n "$TINI_PATH" ]; then
  echo "Using tini at $TINI_PATH"
  exec "$TINI_PATH" -- /usr/local/bin/jenkins.sh "$@"
else
  echo "Tini not found, starting Jenkins directly"
  exec /usr/local/bin/jenkins.sh "$@"
fi
