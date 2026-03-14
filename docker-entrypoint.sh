#!/bin/sh
set -e

CONFIG_FILE="./main/configs/yourConfig.json"

echo "Injecting API keys into config..."

# Use node to safely rewrite the JSON config
node - <<EOF
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('${CONFIG_FILE}', 'utf8'));

// Exact key names from jsonSystemSettings.apiKeys in yourConfig.json
const keys = config.jsonSystemSettings.apiKeys;
if (process.env.WEATHERDOTCOM_API_KEY) keys.api_key  = process.env.WEATHERDOTCOM_API_KEY;
if (process.env.MAPBOX_API_KEY)        keys.map_key  = process.env.MAPBOX_API_KEY;
if (process.env.TOMTOM_API_KEY)        keys.traf_key = process.env.TOMTOM_API_KEY;
if (process.env.HERE_API_KEY)          keys.HERE_key = process.env.HERE_API_KEY;

fs.writeFileSync('${CONFIG_FILE}', JSON.stringify(config, null, 4));
console.log('Config patched successfully.');
EOF

exec "$@"