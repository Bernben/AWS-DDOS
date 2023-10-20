# Define the path to the file where blocked IP addresses are stored.
blocked_ips_file="/path/to/blocklist.txt"

# Tail and sort the access log file 
tail -n 5000 /var/log/nginx/access.log | awk '{ print $1 }' | sort | uniq -c | sort -nr | head -n 200 | awk '{ print $2 }' | while read ip; do
  # Check if the IP is already in the blocklist file
  if grep -Fxq "$ip" "$blocked_ips_file"; then
    echo "IP $ip is already blocked, skipping..."
  elif whois $ip | grep -q 'Amazon'; then
    iptables_cmd="iptables -I INPUT -s $ip -p tcp -m multiport --dports 80,443 -j REJECT --reject-with icmp-port-unreachable -w"
    $iptables_cmd
    # Add the IP to the blocklist file
    echo $ip >> "$blocked_ips_file"
  fi
done
