#!/bin/bash

# ci_post_clone.sh
# This script runs after Xcode Cloud clones the repository
# It creates the Secrets.swift file with secrets from environment variables

echo "Creating Secrets.swift from environment secrets..."

SECRETS_FILE="${CI_PRIMARY_REPOSITORY_PATH}/MorningProof/Services/Secrets.swift"

cat > "$SECRETS_FILE" << EOF
import Foundation

enum Secrets {
    static let claudeAPIKey = "${CLAUDE_API_KEY}"
}
EOF

echo "Secrets.swift created successfully"
