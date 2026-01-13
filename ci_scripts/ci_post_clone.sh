#!/bin/bash

# ci_post_clone.sh
# This script runs after Xcode Cloud clones the repository
# It creates the Config.swift file with secrets from environment variables

echo "Creating Config.swift from environment secrets..."

CONFIG_FILE="${CI_PRIMARY_REPOSITORY_PATH}/MorningProof/Services/Config.swift"

cat > "$CONFIG_FILE" << EOF
import Foundation

enum Config {
    static let claudeAPIKey = "${CLAUDE_API_KEY}"
}
EOF

echo "Config.swift created successfully"
