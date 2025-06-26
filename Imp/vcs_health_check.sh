#!/bin/bash

# -----------------------------------------------------------------------------
# Veritas Cluster Server (VCS) Health Check Script
# -----------------------------------------------------------------------------
# Author: You 😉
# Purpose: Check overall cluster, GAB, LLT, service groups, and resource states
# Usage: Run as root or VCS-enabled user on any cluster node
# -----------------------------------------------------------------------------

#CLUSTER_NAME=$(haconf -display | grep "ClusterName" | awk '{print $3}')
#echo "📡 Cluster Name: $CLUSTER_NAME"
#echo "===================="

# Fetch cluster name from main.cf
CLUSTER_NAME=$(grep -i '^cluster' /etc/VRTSvcs/conf/config/main.cf | awk '{print $2}' | tr -d '()')

echo "📡 Cluster Name: $CLUSTER_NAME"
echo "===================="

echo "Master Node Information"
vxdctl -c mode
echo "--------------------"


# 1️⃣ Check LLT links and port status
echo "🔍 LLT Link Status:"
#lltstat -nvv | grep -E "Node|Link|Status"
lltstat -nvv | head -8
echo "--------------------"

# 2️⃣ Check GAB port membership
echo "🔍 GAB Port Memberships:"
gabconfig -a

echo "--------------------"

# 3️⃣ Check Cluster Systems' Status
echo "🔍 Cluster Nodes Status:"
hastatus -sum | grep "SYSTEM STATE" -A 5

echo "--------------------"

# 4️⃣ Check Service Groups State Summary
echo "🔍 Service Groups Summary:"
hastatus -sum | grep "GROUP STATE" -A 10

echo "--------------------"

# 5️⃣ Check for any failed resources
echo "🔍 Failed Resources (if any):"
hastatus -sum | grep "RESOURCES FAILED" -A 5

echo "--------------------"

# 6️⃣ Check specific service group status (example: cvm, infa_sg)
for grp in cvm infa_sg; do
  echo "🔍 Service Group: $grp"
  hagrp -state $grp
  echo "--------------------"
done

# 7️⃣ Check if any groups are frozen
echo "🔍 Frozen Groups:"
hagrp -list | grep -i Frozen

echo "--------------------"

# 8️⃣ Check for offline/faulted resources
echo "🔍 Resources Offline/Faulted:"
hares -state | egrep "OFFLINE|FAULTED"

echo "--------------------"


echo "Verify CFS Mount point"
df -Th | grep /infa_shared


echo "--------------------"


echo "===================="
echo "✅ Cluster health check completed."
