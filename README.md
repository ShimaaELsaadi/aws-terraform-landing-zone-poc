# AWS Terraform Landing Zone POC

## Introduction

This project implements a Proof of Concept (POC) for an AWS Landing Zone using Infrastructure as Code (IaC) with Terraform. The primary goal is to demonstrate automated, reproducible, and scalable cloud infrastructure deployment on AWS, leveraging Free Tier resources. This README provides a comprehensive overview of the project, including its architecture, Terraform workflows, CI/CD pipeline, and detailed instructions for understanding and operating the infrastructure.

### What is Infrastructure as Code (IaC)?

Infrastructure as Code (IaC) is the practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools. It allows you to define, configure, and manage your infrastructure using code, which can be versioned, reused, and shared. This approach brings significant benefits, including increased speed, consistency, efficiency, and reduced human error in infrastructure deployment and management.

### What is Terraform?

Terraform is an open-source Infrastructure as Code (IaC) tool developed by HashiCorp. It enables you to define and provision datacenter infrastructure using a declarative configuration language (HashiCorp Configuration Language - HCL). Terraform supports a wide range of cloud providers (like AWS, Azure, Google Cloud) and on-premises solutions, allowing you to manage your entire infrastructure from a single workflow. Key concepts in Terraform include:

*   **State:** Terraform maintains a state file (`terraform.tfstate`) that maps real-world resources to your configuration, tracks metadata, and improves performance for large infrastructures. It\'s crucial for Terraform to know what resources it manages.
*   **Backend:** The backend defines where Terraform stores its state file. Using a remote backend (like AWS S3) is essential for team collaboration, as it centralizes the state and enables state locking (e.g., via AWS DynamoDB) to prevent concurrent modifications.
*   **Variables:** Input variables allow you to parameterize your Terraform configurations, making them reusable and flexible across different environments or scenarios.
*   **Modules:** Modules are self-contained, reusable Terraform configurations that encapsulate a set of resources. They promote code reusability, organization, and abstraction, making complex infrastructures easier to manage.
*   **Taint:** The `terraform taint` command manually marks a resource for recreation in the next `terraform apply`. This is useful when a resource becomes unhealthy or needs to be replaced.
*   **Import:** The `terraform import` command allows you to bring existing infrastructure resources under Terraform management. This is useful for adopting Terraform in existing environments.


## Project Structure

This project follows a modular and environment-specific structure to manage Terraform configurations, ensuring clarity, reusability, and maintainability. The main directories are:

```
.github/
├── workflows/
│   └── terraform.yml
envs/
├── staging/
│   ├── backend.tf
│   ├── main.tf
│   ├── output.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── vars.tfvars
└── main/
    ├── backend.tf
    ├── main.tf
    ├── output.tf
    ├── provider.tf
    ├── variables.tf
    └── vars.tfvars
modules/
├── compute/
│   ├── data.tf
│   ├── local.tf
│   ├── main.tf
│   ├── output.tf
│   └── variables.tf
├── logging/
│   ├── IAM.tf
│   ├── main.tf
│   ├── output.tf
│   └── variables.tf
└── network/
    ├── data.tf
    ├── locals.tf
    ├── main.tf
    ├── output.tf
    └── variables.tf
README.md
```

### Component Descriptions:

*   `.github/workflows/`: Contains the GitHub Actions workflow definition (`terraform.yml`) for the Continuous Integration/Continuous Deployment (CI/CD) pipeline.
*   `envs/`: This directory holds environment-specific Terraform configurations. Each sub-directory (`staging`, `main`) contains the main Terraform files for that environment, including backend configuration, variable definitions, and module orchestrations.
*   `modules/`: This directory contains reusable Terraform modules, promoting the DRY (Don\'t Repeat Yourself) principle and simplifying infrastructure management:
    *   `compute/`: Module for provisioning EC2 instances and associated security groups.
    *   `logging/`: Module for setting up centralized logging solutions, including S3 buckets for VPC Flow Logs and CloudWatch Log Groups.
    *   `network/`: Module for configuring core networking components like Virtual Private Clouds (VPCs), subnets, and Internet Gateways.


## How to Build Each Module

This project is structured with reusable Terraform modules for `network`, `compute`, and `logging`. You can use these modules in your environment configurations (e.g., `envs/staging/main.tf` or `envs/main/main.tf`).

### 1. Network Module (`modules/network`)

This module provisions a VPC, public subnets, and an Internet Gateway. It is parameterized to allow flexible network configurations.

**Variables:**
*   `environment`: (string, required) The environment name (e.g., `staging`, `main`). Used for resource naming.
*   `vpc_config`: (map, required) Configuration for the VPC.
    *   `cidr_block`: (string, required) The CIDR block for the VPC (e.g., `"10.0.0.0/16"`).
*   `subnet_config`: (map of maps, required) Configuration for subnets. Each key represents a subnet name.
    *   `cidr_block`: (string, required) The CIDR block for the subnet (e.g., `"10.0.1.0/24"`).
    *   `public`: (bool, required) Set to `true` for public subnets.

    *   **Example Usage (`envs/staging/main.tf` for a single public subnet):**
        ```terraform
        module "network" {
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
        ```

    *   **Example Usage (`envs/main/main.tf` for two public subnets):**
        ```terraform
        module "network" {
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
            subnet2 = {
              cidr_block = "10.0.2.0/24"
              public = true
            }
          }
        }
        ```

### 2. Compute Module (`modules/compute`)

This module provisions EC2 instances and associated security groups. It allows you to define multiple instances with different configurations.

**Variables:**
*   `environment`: (string, required) The environment name (e.g., `staging`, `main`). Used for resource naming.
*   `vpc_id`: (string, required) The ID of the VPC where instances will be launched (obtained from the `network` module output).
*   `instances`: (map of maps, required) Configuration for EC2 instances. Each key represents an instance name.
    *   `instance_type`: (string, required) The EC2 instance type (e.g., `"t2.micro"`).
    *   `subnet_id`: (string, required) The ID of the subnet where the instance will be launched (obtained from the `network` module output).
    *   `key_pair_name`: (string, required) The name of the AWS Key Pair to associate with the instance.
*   `sg_config`: (map, required) Configuration for the security group.
    *   `description`: (string, required) Description for the security group.
    *   `ingress`: (map of maps, required) Ingress rules.
        *   `port`: (number, required) The port number.
        *   `cidrs`: (list of strings, required) List of CIDR blocks allowed to access the port.
    *   `egress`: (map of maps, required) Egress rules.
        *   `from_port`: (number, required) Start port for the egress rule.
        *   `to_port`: (number, required) End port for the egress rule.
        *   `protocol`: (string, required) The protocol (e.g., `"tcp"`, `"all"`).
        *   `cidrs`: (list of strings, required) List of CIDR blocks for egress.

    *   **Example Usage (`envs/staging/main.tf`):**
        ```terraform
        module "compute" {
          source = "../../modules/compute"
          environment = var.environment
          vpc_id = module.network.vpc_id
          instances = {
            web_server = {
              instance_type = "t2.micro"
              subnet_id = module.network.public_subnet_ids["subnet1"]
              key_pair_name = "my-key-pair"
            }
          }
          sg_config = {
            description = "Allow web traffic"
            ingress = {
              http = {
                port = 80
                cidrs = ["0.0.0.0/0"]
              }
              ssh = {
                port = 22
                cidrs = ["0.0.0.0/0"]
              }
            }
            egress = {
              all = {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidrs = ["0.0.0.0/0"]
              }
            }
          }
        }
        ```

### 3. Logging Module (`modules/logging`)

This module sets up centralized logging components, including an S3 bucket for VPC Flow Logs and a CloudWatch Log Group.

**Variables:**
*   `environment`: (string, required) The environment name (e.g., `staging`, `main`). Used for resource naming.
*   `vpc_id`: (string, required) The ID of the VPC for which flow logs will be collected.
*   `log_bucket_name`: (string, required) The name for the S3 bucket where VPC Flow Logs will be stored.
*   `log_group_name`: (string, required) The name for the CloudWatch Log Group.

    *   **Example Usage (`envs/main/main.tf`):**
        ```terraform
        module "logging" {
          source = "../../modules/logging"
          environment = var.environment
          vpc_id = module.network.vpc_id
          log_bucket_name = "${var.environment}-vpc-flow-logs"
          log_group_name = "/${var.environment}/vpc-flow-logs"
        }
        ```


## Branch Details

This project utilizes a branching strategy to manage different environments and infrastructure components. Each branch serves a specific purpose and integrates with the CI/CD pipeline.

### `backend-setup` Branch

*   **Purpose:** This branch is solely dedicated to setting up the Terraform remote backend infrastructure. This includes an S3 bucket for storing Terraform state files and a DynamoDB table for state locking, which are crucial for collaborative Terraform development and preventing concurrent state modifications.
*   **Key Files:** 
```
.
├── README.md
├── main.tf
├── provider.tf
├── variables.tf
└── vars.tfvars
```

The `main.tf` file in this branch contains configurations for:
*   An S3 bucket (`aws_s3_bucket.terraform_state_bucket`) for storing Terraform state files, with versioning and KMS encryption enabled.
*   A DynamoDB table (`aws_dynamodb_table.terraform_locks`) for state locking, preventing concurrent modifications.

*   **Contribution to Pipeline:** A push to this branch triggers a dedicated GitHub Actions workflow that provisions these backend resources. This is a one-time setup process that must be completed before any other environment deployments.


### `staging` Branch

*   **Purpose:** The `staging` branch represents the staging environment. This environment is used for testing and validating infrastructure changes before they are promoted to production. It mirrors the production environment as closely as possible to catch potential issues early.
*   **Key Files:** 
```
├── README.md
├── envs
│   └── pre-prod
│       ├── backend.tf
│       ├── main.tf
│       ├── output.tf
│       ├── provider.tf
│       ├── variables.tf
│       └── vars.tfvars
└── modules
    ├── compute
    │   ├── data.tf
    │   ├── local.tf
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── logging
    │   ├── IAM.tf
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    └── network
        ├── data.tf
        ├── locals.tf
        ├── main.tf
        ├── output.tf
        └── variables.tf
```

The `main.tf` file within `envs/pre-prod` in this branch utilizes the `network` and `compute` modules. Specifically, it configures:
*   A VPC with a single public subnet.
*   A `t2.micro` EC2 instance deployed into this public subnet.
*   A security group allowing SSH (port 22) and HTTP (port 80) access from anywhere (`0.0.0.0/0`).

*   **Contribution to Pipeline:** Any push to the `staging` branch triggers the CI/CD pipeline. The workflow performs `terraform init`, `terraform validate`, `terraform plan`, and `terraform apply` to deploy changes to the staging AWS environment. This allows for rapid iteration and testing of infrastructure code.

### `main` Branch

*   **Purpose:** The `main` branch represents the production environment. It contains the Terraform configuration for the live, operational AWS Landing Zone, designed for stability and reliability. Only thoroughly tested and validated changes from the `staging` environment are merged into `main`.
*   **Key Files:** The `main` branch contains the `envs/main/` directory, which holds the Terraform configuration for the production environment. This includes:
    *   `backend.tf`: Configures the remote backend (S3 and DynamoDB) for the production state.
    *   `main.tf`: Orchestrates the `network`, `compute`, and `logging` modules to build the production infrastructure, potentially with additional logging configurations.
    *   `variables.tf` and `vars.tfvars`: Define environment-specific variables for the production deployment.
*   **Contribution to Pipeline:** Any merge into the `main` branch triggers the CI/CD pipeline. The workflow performs `terraform init`, `terraform validate`, `terraform plan`, and `terraform apply` to deploy changes to the production AWS environment. This ensures that production deployments are triggered only after changes have been validated in staging and merged.


## CI/CD Workflow with GitHub Actions

The project includes a GitHub Actions workflow (`.github/workflows/terraform.yml`) that automates the Terraform deployment process based on branch activity. This ensures continuous integration and continuous deployment for your infrastructure.

### Workflow Triggers and Stages:

*   **`bootstrap-backend` branch:**
    *   **Purpose:** This branch is used to set up the Terraform remote backend (S3 bucket for state and DynamoDB for state locking).
    *   **Workflow:** A push to this branch triggers a workflow that performs `terraform init`, `terraform plan`, and `terraform apply` to provision the backend infrastructure.
    *   **Trigger:** `on: push: branches: [bootstrap-backend]`

*   **`staging` branch:**
    *   **Purpose:** This branch represents the staging environment for testing and validating infrastructure changes.
    *   **Workflow:** Any push to the `staging` branch triggers the CI/CD pipeline. The workflow performs `terraform init`, `terraform validate`, `terraform plan`, and `terraform apply` to deploy changes to the staging AWS environment.
    *   **Trigger:** `on: push: branches: [staging]`
    *   **Deployment:** Changes on `staging` reflect immediately.

*   **`main` branch:**
    *   **Purpose:** This branch represents the production environment, where stable and validated infrastructure changes are deployed.
    *   **Workflow:** Any merge into the `main` branch triggers the CI/CD pipeline. The workflow performs `terraform init`, `terraform validate`, `terraform plan`, and `terraform apply` to deploy changes to the production AWS environment.
    *   **Trigger:** `on: push: branches: [main]`
    *   **Deployment:** This ensures that production deployments are triggered only after changes have been validated in staging and merged.

### To Trigger Deployments via CI/CD:

1.  Make your Terraform code changes in a feature branch.
2.  Create a Pull Request to merge your feature branch into `staging`.
3.  Once merged, the GitHub Actions workflow will automatically deploy to the staging AWS environment.
4.  After successful deployment and testing in staging, create a Pull Request to merge the `staging` branch into `main`.
5.  Upon merging into `main`, the GitHub Actions workflow will automatically deploy to the production AWS environment.


## Running the Project (Manual Execution)

This project is designed to be deployed to AWS using Terraform. Follow these steps to set up and run the project manually for testing or development purposes.

### Prerequisites

*   AWS Account with Free Tier access.
*   AWS CLI configured with appropriate credentials.
*   Terraform CLI installed locally.

### Steps:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ShimaaELsaadi/aws-terraform-landing-zone-poc.git
    cd aws-terraform-landing-zone-poc
    ```

2.  **Initialize Terraform for a specific environment (e.g., `staging`):**
    Navigate to the desired environment directory and initialize Terraform. This will download the necessary providers and set up the S3 backend for state management.
    ```bash
    cd envs/staging
    terraform init
    ```
    *Expected Output (example):*
    ```
    Initializing the backend...
    Initializing provider plugins...
    Terraform has been successfully initialized!
    ```

3.  **Plan the deployment:**
    Generate an execution plan to see what resources Terraform will create.
    ```bash
    terraform plan
    ```
    *Expected Output (example - will vary based on exact configuration):*
    ```
    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:

      # aws_vpc.main will be created
      + resource "aws_vpc" "main" {
          ...
        }

    Plan: 5 to add, 0 to change, 0 to destroy.
    ```

4.  **Apply the deployment:**
    Apply the planned changes to deploy the infrastructure. You will be prompted to confirm.
    ```bash
    terraform apply
    ```
    Type `yes` and press Enter to proceed.
    ```
    Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
    ```

5.  **Destroy resources (optional):**
    To tear down the deployed infrastructure, run the destroy command. You will be prompted to confirm.
    ```bash
    terraform destroy
    ```
    Type `yes` and press Enter to proceed.
    ```
    Destroy complete! Resources: 5 destroyed.
    ```


## Architecture Diagrams

### Overall Landing Zone and CI/CD Pipeline Architecture

The following diagram illustrates the high-level architecture of the AWS Landing Zone and the integrated CI/CD pipeline workflow:

![AWS Landing Zone and CI/CD Pipeline Architecture](/home/ubuntu/aws_landing_zone_diagram.png)

### Backend Setup Architecture

This diagram illustrates the architecture provisioned by the `bootstrap-backend` branch, which sets up the Terraform remote state and locking mechanisms:

![Terraform Backend Setup in AWS](/home/ubuntu/backend_setup_diagram.png)

### Pre-Production (Staging) Environment Architecture

This diagram illustrates the architecture deployed by the `staging` branch (or the `envs/staging/` directory):

![Pre-Production Architecture](/home/ubuntu/pre_prod_architecture.png)

### Production Environment Architecture

This diagram illustrates the expected architecture for the production environment, including the additional logging components:

![Production Architecture](/home/ubuntu/prod_architecture.png)


## Links

*   **GitHub Repository:** [https://github.com/ShimaaELsaadi/aws-terraform-landing-zone-poc](https://github.com/ShimaaELsaadi/aws-terraform-landing-zone-poc)
*   **`backend-setup` branch:** [https://github.com/ShimaaELsaadi/aws-terraform-landing-zone-poc/tree/backend-setup](https://github.com/ShimaaELsaadi/aws-terraform-landing-zone-poc/tree/backend-setup)
*   **`staging` branch:** [https://github.com/ShimaaELsaadi/aws-terraform-landing-zone-poc/tree/staging](https://github.com/ShimaaELsaadi/aws-terraform-landing-zone-poc/tree/staging)