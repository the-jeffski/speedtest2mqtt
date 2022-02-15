#!/bin/bash

## Speedtest2Mqtt Shell script
## Runs the Testing using the OOKLA CLI and posts to MQTT. Skips the results if a known bad server (must be set below).

# Login information For MQTT Broker
mqttuser=
mqttpassword=
mqttbroker=192.168.0.8
mqttport=1883

# Other Settings

homeassistant=false

# Check server ID in case its on the blocklist and if so skip posting results and have another try if retry is enabled
badservers='34881 34931'

# Run SpeedTest and get variables from Json

speedtest_result=$(/usr/bin/speedtest --format=json --accept-license --accept-gdpr)
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

download=$(printf %.2f "$((10 ** 3 * $download * 8 / 10 ** 6))e-3")
upload=$(printf %.2f "$((10 ** 3 * $upload * 8 / 10 ** 6))e-3")
ping_server=$(printf %.3f "$ping_server")
echo $download $upload $ping_server $time_run

speedteststring='{"type":'$download',"attributes":{"time_stamp":"'"$time_stamp"'","ping":'$ping_server',"download":'$download',"upload":'$upload',"server_name":'$server_name',"server_id":'$server_id',"server_location":'$server_location'}}'
echo $speedteststring
echo "**********************************************************************************************"

# If server in bad list then ignore the test
if [[ "$badservers" == *"$server_id"* ]]

then
    # Do nothing
    echo "Test matches bad server so skip posting results"
else
    # Publish to MQTT Broker
    echo "$server_id"
    #mosquitto_pub -h $mqttbroker -p $mqttport -u "$mqttuser" -P "$mqttpassword" -t speedtest/$HOSTNAME/status -m "$speedteststring" -r
fi
