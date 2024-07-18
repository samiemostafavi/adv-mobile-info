#!/bin/bash


# Define login credentials
USERNAME="root" # always root
IP="10.10.5.8" # example: 10.10.5.8
PASSWORD="P02516992h" # check the password from expeca website

# Define the URL and the session cookie
LOGIN_URL="https://$IP/login_exec.cgi"
GET_CONF_URL="https://$IP/mwan1.cgi"
SET_CONF_URL="https://$IP/mwan1_set.cgi"

# Perform the login request and extract the SESSID cookie
LOGIN_RESPONSE=$(curl -k -s -X POST $LOGIN_URL \
    -H "Host: $IP" \
    -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
    -H "Accept-Language: en-US,en;q=0.5" \
    -H "Accept-Encoding: gzip, deflate, br, zstd" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Origin: https://$IP" \
    -H "Connection: keep-alive" \
    -H "Referer: https://$IP/login.cgi" \
    -H "Upgrade-Insecure-Requests: 1" \
    -H "Sec-Fetch-Dest: document" \
    -H "Sec-Fetch-Mode: navigate" \
    -H "Sec-Fetch-Site: same-origin" \
    -H "Sec-Fetch-User: ?1" \
    -H "Priority: u=1" \
    --data-urlencode "username=$USERNAME" \
    --data-urlencode "password=$PASSWORD" \
    --data-urlencode "login=Login" \
    -c -)

# echo "$LOGIN_RESPONSE"

# Check if the login was successful
if ! echo "$LOGIN_RESPONSE" | grep -q "User has been logged in."; then
    echo "Login unsuccessful"
    exit 1
fi
echo "Login successful"

sleep 2

# Extract the SESSID cookie from the login response
SESSID=$(echo "$LOGIN_RESPONSE" | awk '/SESSID/ {print $7}')

# Echo the extracted SESSID value
# echo "Extracted SESSID: $SESSID"
COOKIE="SESSID=$SESSID"

# Send the GET request to retrieve the request_id
GET_CONF_RESPONSE=$(curl -k -s -X GET $GET_CONF_URL -b $COOKIE)
#echo "$GET_CONF_RESPONSE"
# Check if get conf was successful
if ! echo "$GET_CONF_RESPONSE" | grep -q "Mobile WAN Configuration"; then
    echo "Get config unsuccessful"
    exit 1
fi
echo "Get config successful"


# Extract the request_id value from the response
REQUEST_ID=$(echo $GET_CONF_RESPONSE | grep -oP '(?<=<input type="hidden" name="request_id" value=")[^"]+')

# Echo the extracted request_id value
# echo "Extracted request_id: $REQUEST_ID"

sleep 2

# Send the POST request with the retrieved request_id
SET_CONF_RESPONSE=$(curl -k -s -X POST $SET_CONF_URL \
    -H "Host: $IP" \
    -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
    -H "Accept-Language: en-US,en;q=0.5" \
    -H "Accept-Encoding: gzip, deflate, br, zstd" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Origin: https://$IP" \
    -H "Connection: keep-alive" \
    -H "Referer: https://$IP/mwan1.cgi" \
    -H "Cookie: $COOKIE" \
    -H "Upgrade-Insecure-Requests: 1" \
    -H "Sec-Fetch-Dest: document" \
    -H "Sec-Fetch-Mode: navigate" \
    -H "Sec-Fetch-Site: same-origin" \
    -H "Sec-Fetch-User: ?1" \
    -H "Priority: u=1" \
    --data-urlencode "request_id=$REQUEST_ID" \
    --data-urlencode "rat1=" \
    --data-urlencode "rat2=" \
    --data-urlencode "enabled=on" \
    --data-urlencode "apn=" \
    --data-urlencode "apn2=openairinterface" \
    --data-urlencode "username=" \
    --data-urlencode "username2=" \
    --data-urlencode "password=" \
    --data-urlencode "password2=" \
    --data-urlencode "auth=0" \
    --data-urlencode "auth2=0" \
    --data-urlencode "ipmode=4" \
    --data-urlencode "ipmode2=4" \
    --data-urlencode "ipaddr=" \
    --data-urlencode "ipaddr2=" \
    --data-urlencode "phone=" \
    --data-urlencode "phone2=" \
    --data-urlencode "operator=" \
    --data-urlencode "operator2=" \
    --data-urlencode "nettype=0" \
    --data-urlencode "nettype2=0" \
    --data-urlencode "pin=" \
    --data-urlencode "pin2=" \
    --data-urlencode "mru=1500" \
    --data-urlencode "mru2=1500" \
    --data-urlencode "mtu=1500" \
    --data-urlencode "mtu2=1500" \
    --data-urlencode "usepeerdns=1" \
    --data-urlencode "usepeerdns2=1" \
    --data-urlencode "ping=0" \
    --data-urlencode "ping2=1" \
    --data-urlencode "ping_ipaddr=" \
    --data-urlencode "ping_ipaddr2=192.168.70.135" \
    --data-urlencode "ping_sintvl=" \
    --data-urlencode "ping_sintvl2=" \
    --data-urlencode "ping_tout=10" \
    --data-urlencode "ping_tout2=10" \
    --data-urlencode "sw_traffic_limit=" \
    --data-urlencode "sw_traffic_limit2=" \
    --data-urlencode "sw_traffic_warn=" \
    --data-urlencode "sw_traffic_warn2=" \
    --data-urlencode "sw_traffic_start=1" \
    --data-urlencode "sw_traffic_start2=1" \
    --data-urlencode "sim_enabled=1" \
    --data-urlencode "sim_enabled2=1" \
    --data-urlencode "sw_roaming=0" \
    --data-urlencode "sw_roaming2=0" \
    --data-urlencode "sw_traffic=0" \
    --data-urlencode "sw_traffic2=0" \
    --data-urlencode "sw_io_bin0=0" \
    --data-urlencode "sw_io_bin0_2=0" \
    --data-urlencode "sw_io_bin1=0" \
    --data-urlencode "sw_io_bin1_2=0" \
    --data-urlencode "default_sim=2" \
    --data-urlencode "init_state=1" \
    --data-urlencode "sw_timeout_1st=60" \
    --data-urlencode "sw_timeout_2nd=" \
    --data-urlencode "sw_timeout_add=" \
    --data-urlencode "button=Apply")

# Check if the configuration was successfully updated
if echo "$SET_CONF_RESPONSE" | grep -q "Configuration successfully updated."; then
    echo "Success: Configuration successfully updated."
else
    echo "Failure: Configuration failed."
fi


