#!/bin/bash

## Speedtest2Mqtt Shell script

# Login information For MQTT Broker
mqttuser=
mqttpassword=
mqttbroker=xx.xx.xx.xx
mqttport=1883

# Other Settings

homeassistant=false

# Run SpeedTest and get variables from Json

speedtest_result=$( /usr/bin/speedtest --format=json --accept-license --accept-gdpr)
echo "**********************************************************************************************"
echo $speedtest_result

download=$(echo "$speedtest_result" | jq '.download."bandwidth"')
upload=$(echo "$speedtest_result" | jq '.upload."bandwidth"')
ping_server=$(echo "$speedtest_result" | jq '.ping."latency"')
url_test=$(echo "$speedtest_result" | jq '.result."url"' | tr -d \")
time_stamp=$(echo "$speedtest_result" | jq '.timestamp' | tr -d \")
server_name=$(echo "$speedtest_result" | jq '.server."name"')
server_location=$(echo "$speedtest_result" | jq '.server."location"')
server_id=$(echo "$speedtest_result" | jq '.server."id"')

# Result output for log file purposes (set in cron job)
echo $download $upload $ping_server $time_run $server_name 

download=$(printf %.2f "$((10**3 * $download*8/10**6))e-3")
upload=$(printf %.2f "$((10**3 * $upload*8/10**6))e-3")
ping_server=$(printf %.3f "$ping_server")
echo $download $upload $ping_server $time_run


speedteststring='{"type":'$download',"attributes":{"time_stamp":"'"$time_stamp"'","ping":'$ping_server',"download":'$download',"upload":'$upload',"server_name":'$server_name',"server_id":'$server_id',"server_location":'$server_location'}}'
echo $speedteststring
echo "**********************************************************************************************"

# Check server ID in case its on the blocklist

# Publish to MQTT Broker

mosquitto_pub -h $mqttbroker -p $mqttport -u "$mqttuser" -P "$mqttpassword" -t speedtest/$HOSTNAME/status -m "$speedteststring" -r