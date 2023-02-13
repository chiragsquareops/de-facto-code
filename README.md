# De-facto-Infra-Code

``` bash
.
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
    │   │   ├── local.tf
    │   │   ├── provider.tf
    │   │   ├── rds.tf
    │   │   ├── vpc.tf
    │   │   └── worker.tf
    │   └── prod
    │       ├── app_asg.tf
    │       ├── backend.tf
    │       ├── cicd.tf
    │       ├── local.tf
    │       ├── output.tf
    │       ├── provider.tf
    │       ├── queue_asg.tf
    │       ├── rds.tf
    │       └── vpc.tf
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
        └── CICD
            ├── main.tf
            ├── output.tf
            ├── variable.tf
            └── versions.tf
```
