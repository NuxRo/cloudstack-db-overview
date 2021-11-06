#!/bin/bash

#set -x

# this script looks in the cloud database and gives a quick overview of the infrastructure

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin


# please adjust the below with the correct MySQL credentials
dbuser="root"
dbpassword="password"
db="cloud"
dbhost="localhost"

mysql_command="mysql -u"$dbuser" -p"$dbpassword" -h"$dbhost" "$db" -N -s -r"

#################################################################################

echo "--------------------------------"
echo "SUMMARY:"
echo
echo -n "Cloudstack version: "; $mysql_command -e "select version from version where step='"Complete"' order by id desc limit 1;"
echo
echo "Management servers:"
$mysql_command -e "select name,service_ip from mshost where removed is null;"

echo
echo -n "Zones: "; $mysql_command -e "select count(id) from data_center where removed is null;"
echo -n "Pods: "; $mysql_command -e "select count(id) from host_pod_ref where removed is null;"
echo -n "Clusters: "; $mysql_command -e "select count(id) from cluster where removed is null;"
echo -n "Hypervisors: "; $mysql_command -e "select count(id) from host where type='"ROUTING"' and removed is null;"
echo -n "Virtual Machines: "; $mysql_command -e "select count(id) from vm_instance where removed is null;"

echo
echo "Primary Storage (TiB):"
echo -n "- Total: "; $mysql_command -e "select sum(capacity_bytes)/1099511627776 from storage_pool where removed is null;"
echo -n "- Used:  "; $mysql_command -e "select sum(used_bytes)/1099511627776 from storage_pool where removed is null;"

echo
echo "ZONES:"

$mysql_command -e "select name from data_center where removed is null;"

echo
echo "--------------------------------"
echo
echo "Showing pods, clusters and hypervisors for each zone:"
echo

for zone in $($mysql_command -e "select id from data_center where removed is null;")
do
echo
echo "#################################"
echo -n "ZONE: " ; $mysql_command -e "select name from data_center where id="$zone";"
echo -n "SECURITY GROUPS: "; $mysql_command -e "select is_security_group_enabled from data_center where id="$zone";"
echo "PRIMARY STORAGE (TiB): "
echo -n "- Total: "; $mysql_command -e "select sum(capacity_bytes)/1099511627776 from storage_pool where removed is null and data_center_id="$zone";"
echo -n "- Used:  "; $mysql_command -e "select sum(used_bytes)/1099511627776 from storage_pool where removed is null and data_center_id="$zone";"
echo "--------------------------------"
for podid in $( $mysql_command -e "select id from host_pod_ref where removed is null and data_center_id="$zone";" ); do
echo -n "- POD: "; $mysql_command -e "select name from host_pod_ref where id="$podid";"
for clusterid in $($mysql_command -e "select id from cluster where removed is null and data_center_id="$zone" and pod_id="$podid";"); do
echo -n "-- CLUSTER: "
$mysql_command -e "select name from cluster where removed is null and data_center_id="$zone" and pod_id="$podid" and id="$clusterid";"
echo "--- HYPERVISORS:"
$mysql_command -e "select name,private_ip_address,storage_ip_address,public_ip_address from host where removed is null and type='"ROUTING"' and cluster_id="$clusterid";"
done
done
echo "#################################"
done
