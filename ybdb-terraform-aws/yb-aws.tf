terraform{

}

provider aws {
  default_tags {
    tags = local.tags
  }
}

module "yugabyte-db-cluster" {
  source = "github.com/yogendra/terraform-aws-yugabyte"

  availability_zones = local.azs
  cluster_name = "tcpg"
  num_instances = "3"
  region_name = data.aws_region.current.name
  replication_factor = "3"
  root_volume_type = "gp3"
  ssh_keypair = aws_key_pair.ssh-key.key_name
  ssh_private_key = local_file.ssh-key.filename
  subnet_ids = module.infra.public_subnets
  tags = local.tags
  vpc_id = module.infra.vpc_id
}

output "outputs" {
  value = module.yugabyte-db-cluster
}


module "infra"{
  source = "terraform-aws-modules/vpc/aws"

  name = "test-vpc"
  cidr = "10.0.0.0/16"

  azs             = local.azs
  # private_subnets = []
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false

  tags = local.tags
}

# RSA key of size 4096 bits
resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "tcpg-key"
  public_key = tls_private_key.ssh-key.public_key_openssh
}
resource "local_file" "ssh-key" {
  content  = tls_private_key.ssh-key.private_key_openssh
  filename = "${path.module}/sshkey.pem"
  file_permission = "0600"
}
data "aws_region" "current"{}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(sort(distinct(data.aws_availability_zones.available.names)), 0,3)

  tags = {
    yb_owner = "yrampuria"
    yb_task = "demo"
    yb_project = "webinar-tcpg"
    yb_dept = "sales"
  }
}
