# Private Service Connect PoC between 2 projects

Attempt at exposing a CloudSQL service through a PSC endpoint on another project.
PSC is currently limited by the type of backend services an internal TCP/UDP loadbalancer can target, this unfortunately includes **everything except**:
- GCE_VM_IP NEGs
- Instance groups

Therefore, this excludes Cloud Run, CloudSQL, Memory Store, etc services ...
This PoC simply demonstrates the use of an autoscaling GCP managed instance group acting as a proxy layer for a CloudSQL target, and the ability to reach it from another project.

Upon adjusting the `versions.tf/locals` to match the target projects, the PoC is as follows:

1. Retrieve the PSC attached endpoint private IP within the consumer project/network. `https://console.cloud.google.com/net-services/psc/list?project=CONSUMER_PROJECT_ID`
2. Retrieve the sensitive password from the Terraform console `terraform console`; then within the console `nonsensitive(google_sql_user.users.password)`
3. Validate the CloudSQL connection through the PSC PoC `gcloud compute ssh --zone "europe-west1-b" "consumer"  --tunnel-through-iap --project "$CONSUMER_PROJECT_ID"" --command 'sudo apt update && sudo apt install postgresql-client -y && psql -h $PSC_ENDPOINT_IP --username poc -d postgres'` 