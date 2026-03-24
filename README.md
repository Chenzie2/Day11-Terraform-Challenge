# Day 11 Terraform Conditionals Deep Dive

Day 11 of 30-Day Terraform Challenge. How conditionals make infrastructure dynamic, reusable, and environment-aware.

Read the full breakdown:  
[How Conditionals Make Terraform Infrastructure Dynamic and Efficient](https://medium.com/@gracezawadi24/how-conditionals-make-terraform-infrastructure-dynamic-and-efficient-834512c0849c)

## What This Project Covers

Day 11 builds on Day 10 (loops) and introduces conditional logic in Terraform.

Instead of writing separate configurations for different environments, this project demonstrates how to:

* Use ternary expressions for dynamic values  
* Use count to conditionally create resources  
* Safely reference optional resources  
* Build environment-aware infrastructure  
* Validate inputs before deployment  
* Switch between existing vs new infrastructure  

## Key Concepts Learned

### 1. Ternary Expressions

Terraform uses:
```bash
condition ? true_value : false_value
```


```bash
locals {
  instance_type = var.environment == "production" ? "t3.medium" : "t3.micro"
}
```

Development gets t3.micro. Production gets t3.medium.

### 2. Centralized Logic with Locals

```bash
locals {
  is_production     = var.environment == "production"
  instance_type     = local.is_production ? "t3.medium" : "t3.micro"
  min_size          = local.is_production ? 3 : 1
  max_size          = local.is_production ? 10 : 3
  enable_monitoring = local.is_production
}
```

All conditional decisions centralized in one place.

### 3. Conditional Resource Creation

```bash
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = local.enable_monitoring ? 1 : 0
}
```

Development: count = 0 (skipped)  
Production: count = 1 (created)

### 4. Safe Referencing

When count = 0, resource does not exist.

Incorrect:
```bash
value = aws_cloudwatch_metric_alarm.high_cpu.arn
```

Correct:
```bash
value = local.enable_monitoring ? aws_cloudwatch_metric_alarm.high_cpu.arn : null
```

### 5. Input Validation

```bash 
variable "environment" {
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}
```

### 6. Greenfield vs Brownfield

```bash
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
}

resource "aws_vpc" "new" {
  count = var.use_existing_vpc ? 0 : 1
}

locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing.id : aws_vpc.new.id
}
```

## Quick Start

```bash
git clone <your-repo-link>
cd day-11-conditionals
terraform init
```

Development:
```bash
terraform apply -var="environment=dev"
```

Expected:
* instance_type = t3.micro
* min_size = 1
* max_size = 3  
* No monitoring

Production:
```bash
terraform apply -var="environment=production"
```

Expected:
* instance_type = t3.medium
* min_size = 3
* max_size = 10
* Monitoring enabled

Brownfield:
```bash
terraform apply -var="use_existing_vpc=true"
```

Cleanup:
```bash
terraform destroy -var="environment=dev"
```

## Day 10 to Day 11 Progression

Day 10: Loops (for_each, count)  
Day 11: Conditionals (ternary, dynamic decisions)

From static scaling to adaptive infrastructure.

## Key Takeaway

One Terraform configuration serves multiple environments without code duplication.

---

## Author
Grace Zawadi, Software Engineer

#30DayTerraformChallenge #Terraform #IaC #DevOps #AWSUserGroupKenya #EveOps

