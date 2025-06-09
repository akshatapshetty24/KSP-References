
# AWS Public & Private VPC Setup — Interview Summary

## 1. Create VPC
- CIDR block: `10.0.0.0/16`

## 2. Create Subnets
- Public subnet (e.g., `10.0.1.0/24`)
- Private subnet (e.g., `10.0.2.0/24`)

## 3. Create Internet Gateway (IGW)
- Attach IGW to VPC

## 4. Create Route Tables
- Public RT: Route `0.0.0.0/0` → IGW  
- Private RT: Route `0.0.0.0/0` → NAT Gateway

## 5. Create NAT Gateway
- Place in public subnet
- Associate Elastic IP

## 6. Associate Subnets with Route Tables
- Public subnet → Public RT
- Private subnet → Private RT

## 7. Launch Bastion Host EC2 (Public subnet)
- SG allows SSH from anywhere or restricted IPs
- Assign public IP

## 8. Launch Private EC2 (Private subnet)
- SG allows SSH only from bastion host security group
- No public IP

## 9. Connect & Test
- SSH to bastion host using public IP  
- From bastion, SSH into private EC2 using private IP

---

**Bonus:** Enable auto-assign public IP on public subnet for bastion/NAT gateway; keep private subnet isolated.
