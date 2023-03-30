provider "aws" {
    region = var.region
}

variable region {}
variable vpc_cidr_block {}
variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}

//use the az data source, which will query the aws provider and use the region
data "aws_availability_zones" "available" {}

module "myapp-vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "2.64.0"

    name = "myapp-vpc"
    cidr = var.vpc_cidr_block
    private_subnets = var.private_subnet_cidr_blocks
    public_subnets = var.public_subnet_cidr_blocks
    azs = data.aws_availability_zones.available.names 
    
    //by default nat gateway is enabled
    enable_nat_gateway = true

    //also enable this to create a shared common nat gateway 
    //for private subnets so they can route internet traffic through it

    single_nat_gateway = true
    enable_dns_hostnames = true

    tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    }

//add speficic tags to the subnets so they can be identified
//they help so that AWS knows what to connect to
//we also need a tag for ELBs so that kubernetes will create a cloud lb for them

    public_subnet_tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
        "kubernetes.io/role/elb" = 1 
    }

    private_subnet_tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
        "kubernetes.io/role/internal-elb" = 1 
    }

}
