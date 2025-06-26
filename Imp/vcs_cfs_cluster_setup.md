
# 📑 VCS + CVM + CFS Cluster Setup — Two-Node Parallel Cluster

## 📋 Cluster Components

| Component | Purpose |
|:------------|:-------------|
| **LLT** | Low Latency Transport — node-to-node heartbeat |
| **GAB** | Group Membership & Atomic Broadcast — cluster coordination |
| **CVM** | Veritas Volume Manager Cluster — shared disk group management |
| **CFS** | Cluster File System — shared filesystem mount |
| **VCS Service Groups** | Logical grouping of resources managed together |
| **Mount/CFSMount** | Resource to manage clustered mount points |

## 📌 Cluster Overview

- **Two-node cluster:** `node01`, `node02`
- **CVM group**: `cvm` (Parallel)
- **Mount group**: `infa_sg` (Parallel)
- **Shared DiskGroup**: `sharedg`
- **Volume**: `share_vol`
- **Mount Point**: `/infa_shared`

## 📖 Step-by-Step Configuration

### 1️⃣ Check Cluster Communication Status
```bash
gabconfig -a
lltstat -nvv
```

### 2️⃣ CVM Group Setup in `main.cf`

**Group Definition**
```cfg
group cvm (
    SystemList = { node01 = 0, node02 = 1 }
    AutoFailOver = 0
    Parallel = 1
    AutoStartList = { node01, node02 }
)
```

**Resources and Dependencies**
```cfg
CVMVxconfigd cvm_vxconfigd (
    Critical = 0
    CVMVxconfigdArgs = { syslog }
)

CVMCluster cvm_clus (
    CVMClustName = auxlab_poc
    CVMNodeId = { node01 = 0, node02 = 1 }
    CVMTransport = gab
    CVMTimeout = 200
)

CFSfsckd vxfsckd (
    ActivationMode @node01 = { sharedg = sw }
    ActivationMode @node02 = { sharedg = sw }
)

ProcessOnOnly vxattachd (
    PathName = "/bin/sh"
    Arguments = "- /usr/lib/vxvm/bin/vxattachd root"
    RestartLimit = 3
)

# Dependencies
cvm_clus requires cvm_vxconfigd
vxfsckd requires cvm_clus
```

### 3️⃣ Create Disk Group and Volume
```bash
vxdisk -o alldgs list
vxassist -g sharedg make share_vol 5G
vxprint -ht
```

### 4️⃣ Create Mount Directory
```bash
mkdir /infa_shared
```

### 5️⃣ Create Service Group `infa_sg`
```bash
hagrp -add infa_sg
hagrp -modify infa_sg SystemList node01 0 node02 1
hagrp -modify infa_sg AutoStartList node01 node02
hagrp -modify infa_sg Parallel 1
```

### 6️⃣ Add CFSMount Resource to `infa_sg`
```bash
hares -add infa_mount CFSMount infa_sg
hares -modify infa_mount MountPoint "/infa_shared"
hares -modify infa_mount BlockDevice "/dev/vx/dsk/sharedg/share_vol"
hares -modify infa_mount FSType vxfs
hares -modify infa_mount MountOpt "cluster"
```

### 7️⃣ Verify ArgListValues
```bash
hares -display infa_mount | grep ArgListValues
```

### 8️⃣ Enable and Probe Group
```bash
hagrp -enable infa_sg -sys node01
hagrp -enable infa_sg -sys node02
```

### 9️⃣ Check Cluster Status
```bash
hastatus -sum
hares -state
```

## 🔍 Notes:
- Avoid Failover to Parallel group dependencies
- Always verify `hastatus -sum` and `hares -display` to confirm probe and enable status
- CVM must be online before mounting via CFS
- Dependencies between Parallel groups are generally not recommended

## ✅ Health Check Commands
```bash
gabconfig -a
lltstat -nvv
hastatus -sum
hares -state
```

## 📌 Important Attributes

| Attribute            | Description |
|:--------------------|:-------------|
| `AutoFailOver=0`      | No auto failover |
| `Parallel=1`          | Runs on all nodes |
| `AutoStartList`       | Nodes to autostart service group |
| `MountOpt="cluster"`  | Cluster-wide CFS mount |

## ✅ Final Status Check
```bash
hastatus -sum
gabconfig -a
lltstat -nvv
```

## 📖 Summary:
This configures a **two-node VCS CFS cluster** with:
- **Shared volume management via CVM**
- **Clustered filesystem mount managed via VCS**
- **Parallel service groups for both CVM and CFS mount**
- **Clean and verifiable state transitions**

Veritas Cluster Group Action Diagram

flowchart TD
    A[Service Group/Resource State]
    B{Is group in FAULTED state?}
    C{Is group stuck in transition?}
    D[hagrp -clear <group> -sys <system>]
    E[hagrp -flush <group> -sys <system>]
    F[Resume normal operations]

    A --> B
    B -- Yes --> D
    B -- No --> C
    C -- Yes --> E
    C -- No --> F
    D --> F
    E --> F


📌 Summary Table
Situation	Command	Effect
Group is FAULTED after a failure	hagrp -clear <group> -sys <system>	Clears fault status, allows retry or manual operations
Group is stuck in transition (waiting, pending, unknown)	hagrp -flush <group> -sys <system>	Flushes pending actions, resets group’s transition state
