## Create PostgreSQL module + network deployed outside the module and injected into module
This is an example of how to use the module to deploy PostgreSQL module and network cloud infrastructure elements created outside the module and injected to the module.
  
### Using this example
Update terraform.tfvars with the required information.

### Deploy the module
Initialize Terraform:
```
$ terraform init
```
View what Terraform plans do before actually doing it:
```
$ terraform plan
```

Create a `terraform.tfvars` file, and specify the following variables:

```
# Authentication
tenancy_ocid         = "<tenancy_ocid>"
user_ocid            = "<user_ocid>"
fingerprint          = "<finger_print>"
private_key_path     = "<pem_private_key_path>"

# Region
region = "<oci_region>"

# Compartment
compartment_ocid = "<compartment_ocid>"

# Availablity Domain
availablity_domain_name = "<availablity_domain_name>"

# PostgreSQL Password
postgresql_password     = "<postgresql_password>"

```

Use Terraform to provision resources:
```
$ terraform apply
```

### Destroy the module 

Use Terraform to destroy resources:
```
$ terraform destroy -auto-approve
```
