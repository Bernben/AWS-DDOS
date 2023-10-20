# Define the paths for the blocked and good IP address files.
blocked_ips_file="/root/sysadmin/aws_ddos/blocked_ips.txt"
not_aws_ips="/root/sysadmin/aws_ddos/good_ips.txt"

# Tail and sort the access log file as before
tail -n 1000 /var/log/nginx/access.log | awk '{ print $1 }' | sort | uniq -c | sort -nr | head -n 20 | awk '{ print $2 }' | while read ip; do
  # Check if the IP is in the blocked IP list
  if grep -Fxq "$ip" "$blocked_ips_file"; then
    echo "IP $ip is already blocked, skipping..."
  else
    # Check if the IP is in the good IP list
    if grep -Fxq "$ip" "$not_aws_ips"; then
      echo "IP $ip is in the good list, skipping..."
    else
      # If the IP is not in the good list, check if it's owned by Amazon
      if whois $ip | grep -q 'Amazon'; then
        iptables_cmd="iptables -I INPUT -s $ip -p tcp -m multiport --dports 80,443 -j REJECT --reject-with icmp-port-unreachable -w"
        $iptables_cmd
        # Add the IP to the blocked list
        echo $ip >> "$blocked_ips_file"
        echo "IP $ip was successfully blocked and added to the blocked list."
      else
        # Add the IP to the good list
        echo $ip >> "$not_aws_ips"
        echo "IP $ip is not owned by Amazon and has been added to the good list."
      fi
    fi
  fi
done
