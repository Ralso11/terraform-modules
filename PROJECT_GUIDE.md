# The Complete Guide to This Project
### (Written so anyone, even with zero background, can understand it)

This is the fifth project in a small portfolio series. It assumes the
basics from the first project's guide (Git, GitHub, Terraform, CI/CD)
are already familiar. This one is entirely about **modules** — turning
repeated infrastructure code into something reusable.

---

## Part 1 — Why modules, and what problem they solve

By the time the fourth project (ECS/Docker) was finished, the exact same
VPC pattern had been written by hand, from scratch, **three separate
times** — once in the VPC project, once in the ECS project, and
similarly the IAM "assume role" pattern had been written for both Lambda
and ECS. Every time, it was the same shape of code with just a few
different values.

This is exactly the kind of repetition that programming languages solve
with **functions** — write the logic once, call it with different
inputs as many times as needed. Terraform's version of this is a
**module**.

## Part 2 — What actually makes something a module

Structurally, a module is just a folder with `.tf` files — nothing
magical. The difference is in *how* it's written:

- **No hardcoded values.** Instead of `cidr_block = "10.0.0.0/16"`, a
  module says `cidr_block = var.vpc_cidr` — accepting the value from
  whoever uses it, rather than assuming one specific number.
- **No provider or backend configuration.** A module doesn't decide
  which AWS account or region to deploy to, and it doesn't manage its
  own state file — that's entirely the responsibility of whatever
  project *uses* the module.
- **Clear inputs and outputs.** `variables.tf` defines exactly what the
  module needs to know; `outputs.tf` defines exactly what it hands back.
  This is the module's entire "interface" — the only way anything
  outside it can interact with what it builds.

## Part 3 — The `vpc` module, explained

This is a direct generalization of the VPC pattern from the third
project. Compare the two:

**Before (hardcoded, in the VPC project):**
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "vpc-networking-project-vpc" }
}
```

**After (generalized, in the module):**
```hcl
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = { Name = "${var.project_name}-vpc" }
}
```

Two changes: the CIDR is now a variable (so any project can choose its
own network range), and the resource name changed from `"main"` to
`"this"` — a Terraform convention signaling "this is the one and only
instance of this resource type that this module creates," which reads
naturally wherever it's referenced (`aws_vpc.this.id`).

The rest of the module (subnet, internet gateway, route table) follows
the exact same pattern — same resources you've now written multiple
times, just with hardcoded specifics replaced by variables.

## Part 4 — The `iam-role` module and the `for_each` loop

This module is more interesting, because it introduces a genuinely new
Terraform concept: **looping over a list to create multiple resources.**

**The problem it solves:** an IAM role might need zero policies, one
policy, or several. Previous projects always attached exactly one
specific policy, hardcoded:
```hcl
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/..."
}
```

**The module's version:**
```hcl
resource "aws_iam_role_policy_attachment" "this" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}
```

`var.managed_policy_arns` is a **list** of policy ARNs — could be empty,
could have five entries. `for_each = toset(...)` tells Terraform: "for
every distinct item in this list, create one of these resources."
`each.value` inside the block means "whichever specific item we're
currently processing." `toset(...)` converts the list into a *set* (an
unordered collection with no duplicates) — a technical requirement of
`for_each`, not just a style choice.

**Why this matters conceptually:** this is the difference between code
that handles *one specific case* and code that handles *any number of
cases generically*. If a future project needs a role with three
policies attached instead of one, this module handles it automatically
— no new code needed, just a longer list passed in.

## Part 5 — Proving it works: the usage examples

A module that's never actually used is just unverified code. Two
`examples/` projects exist specifically to prove both modules work with
real, deployed infrastructure:

**`examples/vpc-usage/`** calls the `vpc` module once, with specific
values, and deploys a real VPC.

**`examples/iam-role-usage/`** is the more interesting proof — it calls
the **same** `iam-role` module **twice**, with different inputs:
```hcl
module "lambda_role" {
  source               = "../../iam-role"
  assume_role_service  = "lambda.amazonaws.com"
  managed_policy_arns  = ["arn:...AWSLambdaBasicExecutionRole"]
}

module "ecs_role" {
  source               = "../../iam-role"
  assume_role_service  = "ecs-tasks.amazonaws.com"
  managed_policy_arns  = ["arn:...AmazonECSTaskExecutionRolePolicy"]
}
```
Two real IAM roles, for two completely different AWS services, created
from identical underlying code — this is genuinely what "reusable"
means in practice, not just a theoretical claim.

## Part 6 — Why each example gets its own pipeline

Since the repo now has two separate deployable projects
(`vpc-usage` and `iam-role-usage`), each needed its **own** GitHub
Actions workflow file (`terraform.yml` and `iam-role.yml`), each pointed
at a different `working-directory`. A single shared pipeline can't
deploy two independent Terraform projects with separate state files in
one run — each needs to run `terraform init`/`plan`/`apply` in its own
folder, against its own state.

## Part 7 — Cost awareness: not everything needs tearing down

Unlike the VPC and ECS projects (which included things like EC2
instances and Fargate tasks that bill by the hour), **this project's
resources are all genuinely free by themselves**: a bare VPC with
subnets and a route table has no hourly charge, and IAM roles/policies
are never billed regardless of how many exist. `destroy.yml` workflows
were still added for structural consistency with the rest of the
portfolio, but understanding *why* something does or doesn't need to be
torn down — rather than destroying everything reflexively — is itself
a useful skill: it comes down to whether a resource represents compute
time (EC2, Fargate, NAT Gateways) or just configuration/metadata (VPCs,
subnets, IAM roles, security groups).

## Part 8 — Command/concept glossary (new items vs previous projects)

| Term | Plain-language meaning |
|---|---|
| Module | A reusable, self-contained piece of Terraform code with defined inputs and outputs |
| Root module | A Terraform project that gets applied directly (as opposed to one referenced by another) |
| `source` (in a module block) | Tells Terraform where to find a module's code (a relative path, a Git URL, or the public Terraform Registry) |
| `for_each` | Creates one resource per item in a list/set, instead of writing repeated blocks by hand |
| `each.value` | Inside a `for_each` block, refers to the current item being processed |
| `toset(...)` | Converts a list into a set (no duplicates, no guaranteed order) — required by `for_each` |
| `list(string)` | A variable type accepting multiple string values, not just one |

## Part 9 — How to explain this project in an interview

> "After building four separate cloud projects, I noticed I was
> rewriting the same VPC and IAM role patterns by hand each time, so I
> refactored them into reusable Terraform modules — a VPC module and an
> IAM role module that uses a for_each loop to attach any number of
> policies. I proved both modules actually work by deploying real usage
> examples: the IAM role module specifically gets used twice in the same
> example, once configured for Lambda and once for ECS, from identical
> underlying code. This forced me to actually understand the patterns
> I'd been copying, rather than just repeating them."

That story demonstrates a real step up in Terraform maturity — moving
from "I can write infrastructure code" to "I can write infrastructure
code other code can build on."

---

*This document, together with the repo's README.md, covers everything
needed to fully understand, explain, and rebuild this project.*
