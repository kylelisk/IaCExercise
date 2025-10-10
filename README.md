# IaC Exercise - Terraform

Infrastructure as Code exercise using Terraform to deploy a web server on AWS.

# IaC Exercise - AWS Infrastructure with Terraform

Production-grade AWS infrastructure using Terraform with advanced security features including Network Firewall, Application Load Balancer, ECS Fargate, and comprehensive logging.

## 📁 Project Structure

```
.
├── infra/                      # Terraform infrastructure code
│   ├── main.tf                 # Provider and backend configuration
│   ├── variables.tf            # Input variables
│   ├── terraform.tfvars        # Variable values
│   ├── outputs.tf              # Output values
│   ├── networking.tf           # VPC, subnets, route tables
│   ├── ecr.tf                  # Container registry
│   ├── ecs.tf                  # ECS Fargate cluster and services
│   ├── alb.tf                  # Application Load Balancer
│   ├── certificate.tf          # Self-signed TLS certificates
│   └── network_firewall.tf     # AWS Network Firewall
├── webserver/                  # Web application
│   ├── Dockerfile              # Container configuration
│   └── static_page/
│       └── index.html          # Static web content
└── .github/workflows/          # CI/CD pipelines
    ├── terraform-ci.yml        # Infrastructure validation
    ├── terraform-deploy.yml    # Infrastructure deployment
    └── build-push.yml          # Container build & push
```

## 🏗️ Infrastructure Architecture

### Network Architecture (Multi-Layer Security)

```
Internet
   ↓
Internet Gateway
   ↓ [IGW Route Table - routes to firewall]
┌─────────────────────────────────────────┐
│  Firewall Subnets (10.0.4.0/24-5.0/24)  │
│  ├─ Network Firewall Endpoints          │
│  ├─ Allow: HTTP (80), HTTPS (443)       │
│  ├─ Block: Everything else              │
│  └─ Logs: ALERT + FLOW                  │
└─────────────────────────────────────────┘
   ↓
┌──────────────────────────────────────────┐
│  Public Subnets (10.0.0.0/24-1.0/24)     │
│  ├─ Application Load Balancer            │
│  ├─ HTTP → HTTPS redirect                │
│  ├─ HTTPS with self-signed cert          │
│  ├─ Ingress: VPC CIDR only (10.0.0.0/16) │
│  └─ Egress: ECS tasks SG only (port 80)  │
└──────────────────────────────────────────┘
   ↓
┌─────────────────────────────────────────┐
│  Private Subnets (10.0.2.0/24-3.0/24)   │
│  ├─ ECS Fargate Tasks (Nginx)           │
│  ├─ No public IPs                       │
│  ├─ Ingress: ALB SG only (port 80)      │
│  ├─ Egress: HTTPS only (port 443)       │
│  └─ Outbound: NAT Gateway → Firewall    │
└─────────────────────────────────────────┘
```

### Components

#### 1. **Networking (networking.tf)**
- **VPC**: 10.0.0.0/16 with DNS support
- **6 Subnets across 2 AZs**:
  - 2 Public (ALB)
  - 2 Private (ECS)
  - 2 Firewall (Network Firewall endpoints)
- **2 NAT Gateways** for private subnet internet access
- **Internet Gateway** for public access
- **5 Route Tables** for traffic flow control
- **Default Security Group** locked down (deny all)

#### 2. **Network Firewall (network_firewall.tf)**
- **Stateful inspection** of all inbound/outbound traffic
- **Rule Group**: Allow TCP 80 & 443, drop everything else
- **Multi-AZ deployment** for high availability
- **CloudWatch logging**: ALERT + FLOW logs
- **KMS encryption** for logs

#### 3. **Application Load Balancer (alb.tf)**
- **Public-facing** ALB in public subnets
- **HTTP (80)**: Redirects to HTTPS (301)
- **HTTPS (443)**: TLS termination with self-signed certificate
- **Target Group**: Health checks on port 80
- **Security Group**:
  - Ingress: Only from VPC CIDR (10.0.0.0/16) - post-firewall traffic
  - Egress: Only to ECS tasks security group on port 80

#### 4. **TLS Certificates (certificate.tf)**
- **Self-signed certificate** via Terraform TLS provider
- **RSA 2048-bit** private key
- **1-year validity**
- **Imported to ACM** for ALB usage

#### 5. **ECS Fargate (ecs.tf)**
- **ECS Cluster** with Container Insights enabled
- **Fargate Tasks**: 256 CPU / 512 MB memory
- **Auto-scaling**: Ready for future implementation
- **Nginx container** serving static content
- **Private subnets** with no public IPs
- **IAM roles**: Least-privilege policies
  - Execution role: ECR pulls, CloudWatch writes
  - Task role: CloudWatch Logs only
- **Security Group**:
  - Ingress: Only from ALB security group on port 80
  - Egress: Only HTTPS (443) for AWS services (ECR, CloudWatch, S3)
- **CloudWatch Logs** with KMS encryption (7-day retention)

#### 6. **Container Registry (ecr.tf)**
- **ECR repository** with immutable tags
- **Image scanning** on push
- **Lifecycle policy**: Keep last 10 images
- **AES256 encryption**

#### 7. **Monitoring & Observability**
- **CloudWatch Log Groups**:
  - `/ecs/${project_name}` - Application logs
  - `/aws/networkfirewall/${project_name}` - Firewall logs
- **KMS encryption** with automatic key rotation
- **CloudWatch Alarm**: ECS CPU > 80% threshold

## 🔒 Security Features

### Defense in Depth (3 Layers)
1. **Network Firewall** - Layer 3/4/7 deep packet inspection
2. **ALB Security Group** - VPC CIDR only (10.0.0.0/16), egress to ECS only
3. **ECS Security Group** - ALB security group only, egress HTTPS only

### Least-Privilege Network Security
✅ **Network Firewall** - HTTP/HTTPS only (TCP 80, 443), blocks all other traffic  
✅ **ALB Ingress** - VPC CIDR only (10.0.0.0/16), traffic pre-filtered by firewall  
✅ **ALB Egress** - ECS tasks security group only on port 80  
✅ **ECS Ingress** - ALB security group only on port 80  
✅ **ECS Egress** - HTTPS (443) only for AWS service communication  

### Additional Security Best Practices
✅ **Private ECS tasks** - No public IPs, isolated in private subnets  
✅ **Least-privilege IAM** - Minimal permissions for task roles  
✅ **Encrypted logs** - KMS CMK with key rotation  
✅ **HTTPS enforcement** - HTTP redirects to HTTPS  
✅ **Network segmentation** - Dedicated subnets per layer  
✅ **Stateful firewall** - Inspect all traffic bidirectionally  
✅ **Immutable tags** - ECR prevents tag overwrites  
✅ **Image scanning** - Automatic vulnerability scanning  

## 🚀 Getting Started

### Prerequisites
- **Terraform** >= 1.6.0
- **AWS CLI** configured with credentials
- **Docker** (for local container builds)
- **AWS Account** with appropriate permissions

### Initial Setup

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd IaCExercise
   ```

2. **Configure Terraform backend** (first time only)
   ```bash
   # Create S3 bucket for state
   aws s3 mb s3://iacexercise-tfstate --region ca-central-1
   
   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket iacexercise-tfstate \
     --versioning-configuration Status=Enabled
   ```

3. **Review variables**
   ```bash
   cd infra/
   cat terraform.tfvars  # Adjust as needed
   ```

4. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Build and push container**
   ```bash
   # Get ECR login command
   aws ecr get-login-password --region ca-central-1 | \
     docker login --username AWS --password-stdin <account-id>.dkr.ecr.ca-central-1.amazonaws.com
   
   # Build for AMD64 (required for Fargate)
   cd ../webserver
   docker buildx build --platform linux/amd64 -t iac-exercise-app:latest .
   
   # Tag and push
   docker tag iac-exercise-app:latest <ecr-url>:latest
   docker push <ecr-url>:latest
   ```

### Terraform Commands

```bash
# Navigate to infrastructure directory
cd infra/

# Initialize with backend
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output

# Destroy infrastructure
terraform destroy
```

## 🔧 Configuration

### Key Variables (terraform.tfvars)

```hcl
aws_region          = "ca-central-1"
project_name        = "iac-exercise"
environment         = "dev"
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["ca-central-1a", "ca-central-1b"]

# ECS Configuration
ecs_task_cpu        = "256"
ecs_task_memory     = "512"
ecs_desired_count   = 2
container_port      = 80
```

## 🌐 Accessing the Application

After deployment:

```bash
# Get ALB URL
terraform output alb_url

# Access via HTTPS (self-signed cert - browser warning expected)
https://<alb-dns-name>

# Or via HTTP (redirects to HTTPS)
http://<alb-dns-name>
```

**Note**: You'll see a browser security warning because it's a self-signed certificate. This is expected for development environments.

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

#### 1. **Terraform CI** (`terraform-ci.yml`)
- Triggers: Pull requests to `main`
- Steps:
  - Terraform format check
  - Terraform validation
  - Terraform plan
  - Checkov security scanning
- Manual trigger available

#### 2. **Terraform Deploy** (`terraform-deploy.yml`)
- Triggers: Push to `main`
- Steps:
  - Terraform apply (auto-approve)
  - Output infrastructure details
- Manual trigger available

#### 3. **Build & Push Container** (`build-push.yml`)
- Triggers: Changes to `webserver/**`
- Steps:
  - Build Docker image (linux/amd64)
  - Push to ECR with git SHA tag
  - Force ECS service redeployment
- Manual trigger available

### Setting Up GitHub Actions

Add these secrets to your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## 📊 Outputs

After deployment, Terraform provides:

### Networking
- `vpc_id` - VPC identifier
- `public_subnet_ids` - Public subnet IDs
- `private_subnet_ids` - Private subnet IDs  
- `firewall_subnet_ids` - Firewall subnet IDs

### Application
- `ecr_repository_url` - Container registry URL
- `ecs_cluster_name` - ECS cluster name
- `ecs_service_name` - ECS service name
- `alb_dns_name` - ALB DNS endpoint
- `alb_url` - Full HTTPS URL
- `alb_http_url` - HTTP URL (redirects)

### Security
- `acm_certificate_arn` - TLS certificate ARN
- `network_firewall_id` - Firewall ID
- `network_firewall_arn` - Firewall ARN

## 🧪 Testing

### Verify Firewall Rules

```bash
# Test HTTPS (should work)
curl -k https://<alb-dns-name>

# Test HTTP (should redirect to HTTPS)
curl -I http://<alb-dns-name>

# Test blocked port (should timeout)
nc -zv <alb-dns-name> 22
```

### Check Logs

```bash
# ECS application logs
aws logs tail /ecs/iac-exercise --follow

# Network Firewall logs
aws logs tail /aws/networkfirewall/iac-exercise --follow

# CloudWatch Alarms
aws cloudwatch describe-alarms --alarm-names iac-exercise-ecs-cpu-high
```

## 💰 Cost Considerations

Approximate monthly costs (ca-central-1):

| Resource | Cost |
|----------|------|
| Network Firewall | ~$285/month ($0.395/hr/AZ × 2 AZs) |
| NAT Gateways | ~$64/month ($0.045/hr × 2) |
| ALB | ~$18/month |
| ECS Fargate | ~$13/month (2 tasks, 0.25 vCPU, 0.5 GB) |
| KMS Keys | $1/month |
| CloudWatch Logs | <$5/month (7-day retention) |
| ECR Storage | <$1/month |
| **Total** | **~$387/month** |

**Cost Optimization Tips**:
- Remove Network Firewall for dev (~$285 savings)
- Use 1 NAT Gateway (~$32 savings)
- Scale down ECS tasks when not in use

## 🧹 Cleanup

To remove all resources:

```bash
cd infra/
terraform destroy -auto-approve
```

**Note**: The S3 state bucket must be manually deleted if no longer needed.

## 📝 Architecture Decisions

### Why Network Firewall?
- **Deep packet inspection** beyond security groups
- **Centralized logging** of all traffic
- **Layer 7 filtering** (can inspect HTTP/HTTPS)
- **Compliance requirements** for regulated industries

### Why Private Subnets for ECS?
- **Reduced attack surface** - no direct internet exposure
- **Defense in depth** - multiple security layers
- **Best practice** for containerized workloads

### Why Self-Signed Certificate?
- **Development/exercise environment** - no need for public CA
- **Cost-effective** - no certificate purchase required
- **Easy to demonstrate** HTTPS configuration

### Why Separate Firewall Subnets?
- **Routing requirements** - prevents circular dependencies
- **AWS best practice** - hub-and-spoke model
- **Scalability** - easy to add more protected subnets

## 📄 License

This project is for educational purposes.