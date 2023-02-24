# De-facto-Infra-Code

``` bash
├── packer
│   ├── app.json.pkr.hcl
│   ├── application_dependencies.sh
│   ├── config.sh
│   ├── nginx.conf
│   ├── queue_dependencies.sh
│   └── queue.json.pkr.hcl
├── README.md
└── terraform
    ├── env
    │   ├── base
    │   │   └── main.tf
    │   ├── dev
    │   │   ├── app.tf
    │   │   ├── elasticache.tf
    │   │   ├── local.tf
    │   │   ├── provider.tf
    │   │   ├── rds_sq.tf
    │   │   ├── rds.tf
    │   │   ├── vpc.tf
    │   │   └── worker.tf
    │   └── prod
    │       ├── app.tf
    │       ├── backend.tf
    │       ├── local.tf
    │       ├── output.tf
    │       ├── provider.tf
    │       ├── rds.tf
    │       ├── sqs.tf
    │       ├── variable.tf
    │       ├── vpc.tf
    │       └── worker.tf
    └── modules
        ├── ASG
        │   ├── alb.tf
        │   ├── asg.tf
        │   ├── output.tf
        │   ├── variable.tf
        │   └── versions.tf
        ├── Backend
        │   ├── main.tf
        │   ├── outputs.tf
        │   ├── variable.tf
        │   └── version.tf
        ├── CICD
        │   ├── main.tf
        │   ├── output.tf
        │   ├── variable.tf
        │   └── versions.tf
        ├── terraform-aws-aurora-main
        │   ├── examples
        │   │   └── aurora
        │   │       ├── main.tf
        │   │       ├── outputs.tf
        │   │       ├── provider.tf
        │   │       ├── README.md
        │   │       └── versions.tf
        │   ├── IAM.md
        │   ├── LICENSE
        │   ├── main.tf
        │   ├── outputs.tf
        │   ├── README.md
        │   ├── variables.tf
        │   └── versions.tf
        └── terraform-aws-elasticache-redis-main
            ├── examples
            │   └── complete
            │       ├── main.tf
            │       ├── outputs.tf
            │       ├── provider.tf
            │       ├── README.md
            │       └── versions.tf
            ├── IAM.md
            ├── LICENSE
            ├── main.tf
            ├── outputs.tf
            ├── README.md
            ├── tfsec.yaml
            ├── variables.tf
            └── versions.tf
```
