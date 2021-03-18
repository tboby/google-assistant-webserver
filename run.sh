#!/bin/bash
set -e

# Cleanup to be "stateless" on startup, otherwise pulseaudio daemon can't start
rm -rf /var/run/pulse /var/lib/pulse /root/.config/pulse

# Start pulseaudio as system wide daemon; for debugging it helps to start in non-daemon mode
pulseaudio -D --verbose --exit-idle-time=-1 --system --disallow-exit

# Create a virtual audio source; fixed by adding source master and format
echo "Creating virtual audio source: ";
pactl load-module module-virtual-source master=auto_null.monitor format=s16le source_name=VirtualMic

# Set VirtualMic as default input source;
echo "Setting default source: ";
pactl set-default-source VirtualMic


ACCESS_TOKEN=access_token.json

if [ ! -f "/config/$ACCESS_TOKEN" ] && [ -f "/config/$CLIENT_SECRET" ]; then
    echo "[Info] Start WebUI for handling oauth2"
    python3 /oauth.py "/config/$CLIENT_SECRET" "/config/$ACCESS_TOKEN"
elif [ ! -f "/config/$ACCESS_TOKEN" ]; then
    echo "[Error] You need initialize GoogleAssistant with a client secret json!"
    exit 1
fi

exec python3 /gawebserver.py --credentials "/config/$ACCESS_TOKEN" --project-id "$PROJECT_ID" --device-model-id "$DEVICE_MODEL_ID" < /dev/null
