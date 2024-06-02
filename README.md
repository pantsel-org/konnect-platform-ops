# Konnect Platform Ops Demo

A local demo showcasing the utilization of [Terraform](https://www.terraform.io/) and [Helm](https://helm.sh/) for the provisioning of Konnect Control Planes (CPs) and deployment of Kong Data Planes (DPs) within Kubernetes (K8s) environments.

The demo environment is configured with [MinIO](https://min.io/) serving as a Terraform backend, and [HashiCorp Vault](https://www.vaultproject.io/) utilized for the secure storage of credentials and sensitive information.

The Continuous Integration/Continuous Deployment (CI/CD) process employs the execution of [GitHub Actions](https://github.com/features/actions) locally through the utilization of [Act](https://github.com/nektos/act).

## Prerequisites
- [Docker](https://www.docker.com/) and [docker compose](https://docs.docker.com/compose/)
- A functional local Kubernetes (k8s) environment
- [Terraform](https://www.terraform.io/)
- [Helm](https://helm.sh/)
- [`act` - Local GitHub Actions Runner](https://github.com/nektos/act)
- [Hashicorp Vault CLI](https://developer.hashicorp.com/vault/install)
- [Make](https://www.gnu.org/software/make/)

## Prepare the demo environment

Services:
- MinIO: http://localhost:9000
- Hashicorp Vault: http://localhost:8300

To spin-up and prepare your local environment, execute the following command: 

```bash
$ make prepare
```

When preparing the demo environment for the first time, you will be prompted
to provide your `konnect access token`, `s3 access key` and `s3 access secret`.

To get your `konnect access token`, login to your Konnect organization, navigate to the `Personal Access Tokens` page and click `Generate Token`.

![Konnect](./images/konnect_pat.png)

To create your `s3 access key` and `s3 access secret`: 
1. Open `Minio Console` at http://localhost:9000. 
2. Login using `minio-root-user`, `minio-root-password` as username and password.
3. Go to `Access Keys`
4. `Create Access Key`

![Minio Console](./images/minio.png)

## Using the environment

### Build Kong Golden Image

#### Flow

```mermaid
graph LR;
    A[Download Kong Package] --> B[Install custom plugins];
    B --> C[Harden Kong installation];
    C --> D[Add Certificates];
    D --> E[Build];
    E --> F[Scan];
    F --> G[Test];
    G --> H[Publish];
```

#### Run the workflow

```bash
$ act --input image_repo=myrepo/kong --input image_tag=latest workflow_call -W .github/workflows/build-image.yaml    
```

#### Input parameters

| Name       | Description                                                | Required | Default |
|------------|------------------------------------------------------------|----------|---------|
| image_repo | The repository the docker image will be pushed              | Yes     | -       |
| image_tag  | The tag of the docker image                                | Yes     | -       |
| kong_version | The kong gateway ee version to base the resulting image on | No     | 3.7.0.0 |
| continue_on_scan_failure | Continue the workflow even if the security scan fails | No | true |
| publish_image | Publish image to docker registry | No | true |

### Provision Konnect resources (Onboarding pipeline)

The provisioning and deployment process is based on predefined resources. You can find an example in `config/resources.json`. 

#### Resources Configuration Example

```json
{
  "_format_version": "1.0.0",
  "teams": [
    {
      "name": "Team 1",
      "description": "Team 1 is responsible for the development and maintenance of their respective APIs.",
      "roles": [
        {
          "entity_type_name": "Control Planes",
          "entity_region": "eu",
          "role_name": "Admin",
          "entity_name": "CP 1"
        },
        {
          "entity_type_name": "Control Planes",
          "entity_region": "eu",
          "role_name": "Admin",
          "entity_name": "CP 2"
        },
        {
          "entity_type_name": "Control Planes",
          "entity_region": "eu",
          "role_name": "Admin",
          "entity_name": "CP 3"
        }
      ]
    },
    {
      "name": "Team 2",
      "description": "Team 2 is responsible for the development and maintenance of their respective APIs.",
      "roles": [
        {
          "entity_type_name": "Control Planes",
          "entity_region": "eu",
          "role_name": "Admin",
          "entity_name": "CP 4"
        },
        {
          "entity_type_name": "Control Planes",
          "entity_region": "eu",
          "role_name": "Admin",
          "entity_name": "CP 5"
        },
        {
          "entity_type_name": "Control Planes",
          "entity_region": "eu",
          "role_name": "Admin",
          "entity_name": "CP 6"
        }
      ]
    }
  ],
  "control_planes": [
    {
      "name": "CP 1"
    },
    {
      "name": "CP 2"
    },
    {
      "name": "CP 3"
    },
    {
      "name": "CP 4"
    },
    {
      "name": "CP 5"
    },
    {
      "name": "CP 6"
    }
  ],
  "control_plane_groups": [
    {
      "name": "CP Group 1",
      "labels": {
        "cloud": "gcp"
      },
      "control_planes": [
        "CP 1"
      ]
    },
    {
      "name": "CP Group 2",
      "labels": {
        "cloud": "gcp"
      },
      "control_planes": [
        "CP 2"
      ]
    },
    {
      "name": "CP Group 3",
      "labels": {
        "cloud": "on-prem"
      },
      "control_planes": [
        "CP 1",
        "CP 4",
        "CP 5"
      ]
    },
    {
      "name": "CP Group 4",
      "labels": {
        "cloud": "aws"
      },
      "control_planes": [
        "CP 1"
      ]
    },
    {
      "name": "CP Group 5",
      "labels": {
        "cloud": "aws"
      },
      "control_planes": [
        "CP 6"
      ]
    }
  ]
}
```
The above configuration will result in the following high level setup

```mermaid
graph TD;
  subgraph Konnect
      A[Team 1]
      B[Team 2]
      C[CP 1]
      D[CP 2]
      E[CP 3]
      F[CP 4]
      G[CP 5]
      H[CP 6]
    end

    subgraph GCP
      direction RL
        I[ Control Plane Group 1]
        J[ Control Plane Group 2]
        N[Kong DP]
        O[Kong DP]
    end


    subgraph On Prem
      direction RL
        K[ Control Plane Group 3]
        P[Kong DP]
    end

    subgraph AWS
      direction RL
        L[ Control Plane Group 4]
        M[ Control Plane Group 5]
        Q[Kong DP]
        R[Kong DP]
    end

    A --> C
    A --> D
    A --> E
    B --> F
    B --> G
    B --> H
    C -.-> K
    E -.-> L
    F -.-> K
    G -.-> K
    H -.-> M
    D -.-> J
    C -.-> I
    I --> N
    J --> O
    K --> P
    L --> Q
    M --> R

```

#### Provisioning flow

```mermaid
graph TD;
    A[Create Teams]
    B[Provision Team CPs]
    C[Create CP Groups]
    D[Add DP Certificates]
    E[Assign CPs to CP Groups]
    F[Create System Accounts]
    G[Assign Team memberships] --> H[Configure CP Role Assignments]
    J[Create System Account Tokens] --> I[Store Tokens in Vault]

    A --> B
    B --> D
    B -.-> C
    C -.-> D
    C -.-> E
    B --> F
    F --> G
    F --> J
```

#### Run the Workflow

To provision Konnect resources and deploy the DP, execute the following command: 

```bash
$ act \
    --input action=provision \
    --input config_file=config/resources.json \
    workflow_dispatch -W .github/workflows/main.yaml
```

#### Input parameters

| Name       | Description                                                | Required | Default |
|------------|------------------------------------------------------------|----------|---------|
| action     | The action to perform (provision or destroy)                | Yes      | provision |
| config_file| The path to the configuration file                          | Yes      | -       |

#### Deprovisioning 

To clean up everything on Konnect and Kubernetes, execute the following command:

```bash
$ act \
    --input action=destroy \
    --input config_file=config/resources.json \
    workflow_dispatch -W .github/workflows/main.yaml
```