
# AWS Public & Private VPC Setup — Interview Summary with Creation Steps

## 1️⃣ Create VPC
- Go to **VPC Dashboard → Your VPCs → Create VPC**
- Name: `my-vpc`
- CIDR block: `10.0.0.0/16`

## 2️⃣ Create Subnets
- **Public Subnet**
  - Name: `public-subnet`
  - CIDR: `10.0.1.0/24`
  - Enable Auto-assign Public IP
- **Private Subnet**
  - Name: `private-subnet`
  - CIDR: `10.0.2.0/24`

## 3️⃣ Create Internet Gateway (IGW)
- Go to **Internet Gateways → Create**
- Attach to `my-vpc`

## 4️⃣ Create Route Tables
- **Public Route Table**
  - Create new
  - Add Route: `0.0.0.0/0` → IGW
  - Associate with `public-subnet`
- **Private Route Table**
  - Create new
  - Add Route: `0.0.0.0/0` → NAT Gateway (after creating NAT)
  - Associate with `private-subnet`

## 5️⃣ Create NAT Gateway
- Go to **NAT Gateways → Create NAT Gateway**
- Subnet: `public-subnet`
- Allocate new Elastic IP

## 6️⃣ Create Security Groups
- **Bastion SG**
  - Allow SSH (22) from your IP or `0.0.0.0/0`
- **Private EC2 SG**
  - Allow SSH (22) from Bastion SG only

## 7️⃣ Launch Bastion Host EC2 (Public subnet)
- AMI: Amazon Linux 2
- Subnet: `public-subnet`
- Auto-assign Public IP: Enabled
- Security Group: `bastion-sg`
- Key pair: Create or use existing

## 8️⃣ Launch Private EC2 (Private subnet)
- AMI: Amazon Linux 2
- Subnet: `private-subnet`
- Auto-assign Public IP: Disabled
- Security Group: `private-sg`
- Key pair: Same as Bastion

## 9️⃣ Connect & Test
- SSH into Bastion:
  ```bash
  ssh -i "key.pem" ec2-user@<bastion-public-ip>
  ```
- From Bastion, SSH into Private EC2:
  ```bash
  ssh -i "key.pem" ec2-user@<private-ec2-private-ip>
  ```

---

## ✅ Recap
- VPC with public and private subnets
- Internet Gateway for public access
- NAT Gateway for private outbound internet
- Bastion Host for secure SSH access to private EC2
- Correctly configured security groups and routing

