# Terraform Modules

📖 Want the full, beginner-friendly walkthrough of every step, command,
and decision made in this project? See
[PROJECT_GUIDE.md](./PROJECT_GUIDE.md).

## What is this project, in one sentence?

A small library of reusable Terraform modules — a VPC module and an IAM
role module — refactored from patterns repeated across four earlier
projects, each proven working with real, deployed usage examples.

## Why this project exists

The first four projects in this series
([terraform-cicd-project](https://github.com/Ralso11/terraform-cicd-project),
[lambda-api-project](https://github.com/Ralso11/lambda-api-project),
[vpc-networking-project](https://github.com/Ralso11/vpc-networking-project),
[ecs-docker-project](https://github.com/Ralso11/ecs-docker-project))
each wrote similar patterns (a VPC, an IAM assume-role policy) by hand,
from scratch, every time. This project generalizes those patterns into
**reusable modules** — the Terraform equivalent of turning repeated code
into a function. It's both new portfolio content and a genuine test of
whether the earlier patterns were actually understood, not just
copy-pasted.

## Structure

```
terraform-modules/
├── vpc/                    # reusable VPC + subnet + networking module
├── iam-role/                # reusable "assume role for a service" module
└── examples/
    ├── vpc-usage/            # real, deployed example using the vpc module
    └── iam-role-usage/       # real, deployed example using the iam-role
                                module TWICE — once for Lambda, once for ECS
```

Modules never configure their own AWS provider or Terraform backend —
whatever *uses* them does. Only the `examples/` projects have
`backend.tf` and a `provider` block.

## The two modules

### `vpc/`
Creates a VPC, a public subnet, an internet gateway, and a route table.
Takes `project_name`, `aws_region`, `vpc_cidr`, and
`public_subnet_cidr` as inputs; outputs the VPC ID, public subnet ID,
and CIDR block.

### `iam-role/`
Creates an IAM role that a specified AWS service (Lambda, ECS, or any
other) can assume, with zero or more managed policies attached. Takes
`role_name`, `assume_role_service`, and a **list** of
`managed_policy_arns`. Uses a `for_each` loop to attach any number of
policies without repeating code — proven by using the exact same module
for both a Lambda-style role and a completely different ECS-style role
in the usage example.

## Problems & fixes — quick reference

| Problem | Why it happened | How it was fixed |
|---|---|---|
| `terraform fmt -check` failed on the VPC usage example | Inconsistent spacing when typed into the terminal | Rewrote the file with correctly aligned formatting |
| A long heredoc paste got interrupted, leaving the terminal stuck waiting for input | Multi-line pastes into Git Bash occasionally get cut off mid-write | Recognized the stuck `>` prompt, closed it with `EOF`, and rewrote the file cleanly in one paste |
| IAM role creation for the second example failed until the deployer's policy was updated | The original inline policy only covered the state bucket, not IAM role creation (this project genuinely does that for the first time) | Added a scoped `IamRoleForModulesDemo` statement, limited to `modules-demo-*` role names |

## Cost notes

The VPC example (bare VPC, subnets, internet gateway, route table) and
the IAM role example (IAM roles + policy attachments) are **both
zero-cost by themselves** — no hourly charges apply to either. They were
still destroyed/left running deliberately with the same
`destroy.yml`-per-example pattern as other projects, for structural
consistency and good habit, not because leaving them up would cost
anything.

## How to reproduce this project

1. Refactor a repeated Terraform pattern (e.g. a VPC block you've
   written more than once) into its own folder with `main.tf`,
   `variables.tf`, `outputs.tf` — no provider or backend block inside.
2. Replace hardcoded values with `variable` references; give sensible
   defaults only where a default genuinely makes sense.
3. Write a small `examples/` project that calls the module with
   `source = "../../module-folder"` and real values.
4. Add a `backend.tf` and provider block to the **example**, not the
   module.
5. Deploy the example through the same CI/CD pattern as previous
   projects, to prove the module actually works.

## What's next (possible future additions)

- [ ] Add a module for the ECS cluster/task/service pattern.
- [ ] Publish these modules to the public Terraform Registry.
- [ ] Add input validation (`validation` blocks) to catch bad values
      before `apply` even runs.
