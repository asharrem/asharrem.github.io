#!/bin/bash

STORAGE_UUID="storage_mount_point_name"
CAMERA_LABEL="filename_prefix"
HTTP_USER="nx_digestauth_user"
HTTP_PASSWORD="secret_password"
DEVICE_ID="camera_device_id"
IMAGE_SIZE="1920x1080"

/usr/bin/wget -O "/mnt/${STORAGE_UUID}/timelapse/${CAMERA_LABEL}_$(date +%Y%m%d_%H%M%S).jpg" \
  --no-check-certificate \
  --http-user="${HTTP_USER}" \
  --http-password="${HTTP_PASSWORD}" \
  "https://127.0.0.1:7001/rest/v3/devices/${DEVICE_ID}/image?size=${IMAGE_SIZE}&streamSelectionMode=forcedPrimary"
