#!/usr/bin/env bash
#
# Get Memory in use by LXC
# By: Miguel Clara
#
# DESC: Even inside a linux container shell, tools like top, etc will show stats
# regarding the whole system
# This script will list the memory in use by each LXC
# which is recorded in /sys/fs/cgroup/memory...
# The Script also lists the limits set on the LXC config files
#

LXC_CONFIG_PATH_AUTO='/etc/lxc/auto' # Adapt if needed, I prefer to list only the config in "auto"

# Define some fancy colors
txtrst=$(tput sgr0)		# text reset
txtred=$(tput setaf 1)		# text red
txtgreen=$(tput setaf 2)	# text green
txtbold=$(tput bold)		# text in bold

function sum() {
  # using array for totals
  # 0=mem_limit 1=memsw_limit 2=mem_usage 3=memsw_usage
  i=$2
  total[$i]=$(expr ${total[$i]} + $1)
}

# Clear the scren
clear

# Display Header
printf "##### LXC Memory Usage Statistics #####\n\n"
printf "%-20s   %-25s %-20s\n" "Name" "---  Limit  (MB) ---" "---  Usage  (MB) ---"
printf "%-20s %10s| %15s% 10s|%10s\n" ";" "mem" "memsw(*)     " "mem" "memsw(*)"


for file in $LXC_CONFIG_PATH_AUTO/*.*; do
	lxc_name=`cat $file|sed -n 's/^lxc.utsname = //p'`
	
	mem_limit=$(expr `lxc-cgroup -n $lxc_name memory.limit_in_bytes` / 1024 / 1024)
	memsw_limit=$(expr `lxc-cgroup -n $lxc_name memory.memsw.limit_in_bytes` / 1024 / 1024)
	
	mem_usage=$(expr `lxc-cgroup -n $lxc_name memory.usage_in_bytes` / 1024 / 1024)
	memsw_usage=$(expr `lxc-cgroup -n $lxc_name memory.memsw.usage_in_bytes` / 1024 / 1024)
	
	# sum limts and usage in bytes
	sum $mem_limit 0
	sum $memsw_limit 1
	sum $mem_usage 2
	sum $memsw_usage 3
	
	# Display info for each container
	if [ $memsw_usage -lt $memsw_limit ] || [ $mem_usage -lt $mem_limit ]; then
	  printf "${txtred}%-20s${txtrst} %10s|%10s      ${txtgreen}%10s${txtrst}|${txtgreen}%10s${txtrst}\n" "$lxc_name" "$mem_limit MB" "$memsw_limit MB" "$mem_usage MB" "$memsw_usage MB"
	else
	  printf "${txtred}%-20s${txtrst} %10s|%10s      ${txtred}%10s${txtrst}|${txtred}%10s${txtrst}\n" "$lxc_name" "$mem_limit MB" "$memsw_limit MB" "$mem_usage MB" "$memsw_usage MB"
	fi
done

# Display Totals
printf "%.s-" {1..70};echo
if [ $memsw_usage -lt $memsw_limit ] || [ $mem_usage -lt $mem_limit ]; then
  printf "${txtred}%-20s${txtrst} %10s|%10s      ${txtgreen}%10s${txtrst}|${txtgreen}%10s${txtrst}\n" "Totals: " "${total[0]} MB" "${total[1]} MB" "${total[2]} MB" "${total[3]} MB"
else
  printf "${txtred}%-20s${txtrst} %10s|%10s      ${txtred}%10s${txtrst}|${txtred}%10s${txtrst}\n" "Totals: " "${total[0]} MB" "${total[1]} MB" "${total[2]} MB" "$toltal[3] MB"
fi
	
	
printf "\n${txtbold}(*)${txtrst}: memsw means memory + swap, its not just swap\n"
