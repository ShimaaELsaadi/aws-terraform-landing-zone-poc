module "vpc" {
  source = "../../modules/network"
  environment = var.environment
  vpc_config = {
    cidr_block = "10.0.0.0/16"
  }
  subnet_config = {
    subnet1 = {
      cidr_block = "10.0.1.0/24"
      public = true
    }
  }
}
module "instances" {
  source = "../../modules/compute"
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  instances = {
    instance1 = {
      instance_type = "t2.micro"
      subnet_id = module.vpc.subnet_ids["subnet1"]
      key_pair_name = "instance-key-pair"
    }
  }
  sg_config = {
    description = "allow ssh and http"
    ingress = {
      ssh = {
        port  = 22
        cidrs = ["0.0.0.0/0"]
      }
      http = {
        port  = 80
        cidrs = ["0.0.0.0/0"]
      }
    }
    egress = {
      all = {
        from_port = 0
        to_port   = 0
        cidrs     = ["0.0.0.0/0"]
      }
    }
  }
}