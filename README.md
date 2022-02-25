# AWS VPC Peering with Terraform

Initially this was just auto-generated Terraform code from Former2. It wasn't very pretty or DRY so I refactored it entirely. 
This HCL snippet is part of a small project for testing Former2 and Duo CloudMapper.
Use at your own risk, no implicit or explicit warranty is provided regarding anything.

## Description

This HCL plan creates 3 peered VPCs (full mesh) with one subnet in each VPC.
Each subnet resides in a unique AZ. Each VPC comes with its own IGW for internet access.
One non-default route table with any-to-any connectivity between VPCs and internet access is attached to each subnet.
One EC2 instance with wide-open ingress SSH/HTTPS is then spun up in each subnet, for a total of 3 instances.
Each EC2 instance gets a public IP. EC2 instances can be SSHd into because each VPC points to its IGW for Internet access.

### Dependencies

Replace the private key file with your own key for ec2-user SSH access. You must manually create the SSH keypair on EC2 before running this HCL plan.

## Authors

Chris Paggen 

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route.defaultRoutes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.vpcRoutes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.rtassoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.myvpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_peering_connection.eastToHub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_vpc_peering_connection.eastToWest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_vpc_peering_connection.westToHub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_ami.amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_ip_addresses"></a> [instance\_ip\_addresses](#output\_instance\_ip\_addresses) | n/a |
| <a name="output_instance_pubip_addresses"></a> [instance\_pubip\_addresses](#output\_instance\_pubip\_addresses) | n/a |
<!-- END_TF_DOCS -->
