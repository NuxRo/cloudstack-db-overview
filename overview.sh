#!/bin/bash

#set -x

# this script looks in the cloud database and gives a quick overview of the infrastructure

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin


# please adjust the below with the correct MySQL credentials
dbuser="root"
dbpassword="password"
db="cloud"

mysql_command="mysql -u$dbuser -p$dbpassword $db -N -s -r"

#################################################################################

echo "Showing zones:"
echo

$mysql_command -e "select id,name from data_center where removed is null;"


echo
echo "Showing pods and clusters for each zone:"
echo

for zone in $($mysql_command -e "select id from data_center where removed is null;")
do
echo
echo "#################################"
echo -n "ZONE: " ; $mysql_command -e "select name from data_center where id="$zone";"

echo "PRIMARY STORAGE (TiB): "
echo -n "Total: "; $mysql_command -e "select sum(capacity_bytes)/1099511627776 from storage_pool where removed is null and data_center_id="$zone";"
echo -n "Used:  "; $mysql_command -e "select sum(used_bytes)/1099511627776 from storage_pool where removed is null and data_center_id="$zone";"
for podid in $( $mysql_command -e "select id from host_pod_ref where removed is null and data_center_id="$zone";" ); do
echo -n "- POD: "; $mysql_command -e "select name from host_pod_ref where id="$podid";"
#$mysql_command -e "select name from cluster where removed is null and data_center_id="$zone" and pod_id="$podid";"
for clusterid in $($mysql_command -e "select id from cluster where removed is null and data_center_id="$zone" and pod_id="$podid";"); do
echo -n "-- CLUSTER: "
$mysql_command -e "select name from cluster where removed is null and data_center_id="$zone" and pod_id="$podid" and id="$clusterid";"
echo "--- HYPERVISORS:"
$mysql_command -e "select name from host where type='"ROUTING"' and cluster_id="$clusterid";"
done
done
echo "#################################"
done
