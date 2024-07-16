#!/bin/bash


# Define login credentials
USERNAME="root" # always root
#IP="10.10.5.6" # example: 10.10.5.8
IP="10.10.5.8" # example: 10.10.5.8
#PASSWORD="P02516851h" # check the password from expeca website
PASSWORD="P02516992h" # check the password from expeca website

# Define the URL and the session cookie
LOGIN_URL="https://$IP/login_exec.cgi"
GET_CONF_URL="https://$IP/index.cgi"

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
# Check if get conf was successful
if ! echo "$GET_CONF_RESPONSE" | grep -q "Mobile Connection"; then
    echo "Get config unsuccessful"
    exit 1
fi
echo "Get config successful"

# echo "$GET_CONF_RESPONSE"


# Fetch the HTML content
html_content=$GET_CONF_RESPONSE

# Extract the specific part from the HTML content
extracted_content=$(echo "$html_content" | sed -n '/<td nowrap align="center" class="header">Mobile Connection<\/td>/,/<\/table>/p')

# Remove HTML tags and keep only the content
cleaned_content=$(echo "$extracted_content" | sed 's/<[^>]*>//g' | sed '/^\s*$/d')

# echo $cleaned_content

# Initialize variables
json="{"
current_header=""
section_content=""

TYPE1='(Mobile Connection|Primary LAN|Secondary LAN|Tertiary LAN|Peripheral Ports|System Information)'
TYPE2='(Mobile Connection|ETH0|ETH1|ETH2|Peripheral Ports|System Information)'

# Check if 'ETH0' is in the cleaned_content
if [[ "$cleaned_content" == *"ETH0"* ]]; then
  SEPARATORS="$TYPE2"
else
  SEPARATORS="$TYPE1"
fi

# Read the cleaned content line by line
while IFS= read -r line; do
    if [[ "$line" =~ $SEPARATORS ]]; then
        # If we encounter a new header, process the previous section
        if [ -n "$current_header" ]; then
            # Process the section content to extract key-value pairs
            key_value_pairs=""
            while IFS= read -r kv_line; do
                if [[ "$kv_line" == *:* ]]; then
                    key=$(echo "$kv_line" | awk -F': ' '{print $1}' | xargs)
                    value=$(echo "$kv_line" | awk -F': ' '{print $2}' | xargs)
                    key=$(echo "$key" | sed 's/"/\\"/g')
                    value=$(echo "$value" | sed 's/"/\\"/g')
                    key_value_pairs+=$(printf '"%s":"%s",' "$key" "$value")
                fi
            done <<< "$section_content"

            # Remove trailing comma
            if [ -n "$key_value_pairs" ]; then
                key_value_pairs=${key_value_pairs%,}
            fi

            # Add header and key-value pairs to JSON object
            json+=$(printf '"%s":{%s},' "$(echo "$current_header" | xargs)" "$key_value_pairs")
        fi

        # Set the new current header
        current_header="$line"
        section_content=""
    else
        # Accumulate the section content
        section_content+="$line"$'\n'
    fi
done <<< "$cleaned_content"

# Process the last section
if [ -n "$current_header" ]; then
    # Process the section content to extract key-value pairs
    key_value_pairs=""
    while IFS= read -r kv_line; do
        if [[ "$kv_line" == *:* ]]; then
            key=$(echo "$kv_line" | awk -F': ' '{print $1}' | xargs)
            value=$(echo "$kv_line" | awk -F': ' '{print $2}' | xargs)
            key=$(echo "$key" | sed 's/"/\\"/g')
            value=$(echo "$value" | sed 's/"/\\"/g')
            key_value_pairs+=$(printf '"%s":"%s",' "$key" "$value")
        fi
    done <<< "$section_content"

    # Remove trailing comma
    if [ -n "$key_value_pairs" ]; then
        key_value_pairs=${key_value_pairs%,}
    fi

    # Add header and key-value pairs to JSON object
    json+=$(printf '"%s":{%s},' "$(echo "$current_header" | xargs)" "$key_value_pairs")
fi

# Remove trailing comma and close JSON object
json=${json%,}
json+="}"

# Output the final JSON object
echo "$json" | jq .
