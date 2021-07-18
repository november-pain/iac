import boto3
from jinja2 import Template
import string
import random
import logging
import python_terraform as pt
import sys


DEBUG = True
output_cap = not DEBUG

# put the dns name of a hosted zone in variable.tf file
def get_hosted_zone_dns():
    route53_client = boto3.client('route53')
    hosted_zone_dns = route53_client.list_hosted_zones()['HostedZones'][0]['Name']
    DEBUG and print("route53 hosted zone dns name: " + hosted_zone_dns)
    return hosted_zone_dns


def create_bucket_for_backend(bucket_name, owner_id):
    try:
        s3_client = boto3.client('s3')
        s3_client.create_bucket(Bucket=bucket_name)
        waiter = s3_client.get_waiter('bucket_exists')
        waiter.wait(Bucket=bucket_name, ExpectedBucketOwner=owner_id)
    except ClientError as e:
        logging.error(e)
        DEBUG and print(e)
        return False
    return True


def parse_j2_template(hosted_zone_dns, bucket_name):
    with open('variables.tf.j2', "r") as f:
        template_var = Template(f.read())
    template_var.stream(hosted_zone_dns_name=hosted_zone_dns, bucket_name=bucket_name).dump('variables.tf')

    with open('backend.tf.j2', "r") as f:
        template_back = Template(f.read())
    template_back.stream(backend_bucket_name=bucket_name).dump('backend.tf')

    with open('.terraform/terraform.tfstate.j2', "r") as f:
        template_state = Template(f.read())
    template_state.stream(bucket_name=bucket_name).dump('.terraform/terraform.tfstate')


def generate_valid_bucket_name():
    return "terraform-state-file-bucket-" + ''.join(random.choice(string.ascii_lowercase + string.digits) for char in range(8))


def terraform_init(tf):
    return_code, stdout, stderr = tf.fmt(diff=DEBUG, capture_output=output_cap)
    print("-"*80)
    return_code, stdout, stderr = tf.init(capture_output=output_cap)
    print("-"*80)
    return_code, stdout, stderr = tf.validate(capture_output=output_cap)
    print("-"*80)


def deploy(tf, force=False):
    return_code, stdout, stderr = tf.fmt(diff=DEBUG, capture_output=output_cap)
    print("-"*80)
    return_code, stdout, stderr = tf.validate(capture_output=output_cap)
    print("-"*80)
    return_code, stdout, stderr = tf.plan(capture_output=output_cap)
    print("-"*80)
    return_code, stdout, stderr = tf.apply(capture_output=output_cap, skip_plan=force)
    print("-"*80)


def main(argv):
    sts_client = boto3.client('sts')
    owner_id = sts_client.get_caller_identity()["Account"]
    DEBUG and print(owner_id)
    tf = pt.Terraform()

    if argv[0] == "init":
        terraform_backend_bucket_name = generate_valid_bucket_name()
        hosted_zone_dns = get_hosted_zone_dns()
        create_bucket_for_backend(terraform_backend_bucket_name, owner_id)
        parse_j2_template(hosted_zone_dns, terraform_backend_bucket_name)
        terraform_init(tf)

    elif argv[0] == "deploy":
        if len(argv) == 2 and argv[1] == "-f" or argv[1] == "--force":
            deploy(tf, True)
        else: deploy(tf)

    elif argv[0] == "destroy":
        return_code, stdout, stderr = tf.destroy(input=False, capture_output=output_cap)
        if len(argv) == 2 and argv[1] == "--with-backend":
            s3_res = boto3.resource('s3')
            for bucket in s3_res.buckets.all():
                bucket.objects.all().delete(ExpectedBucketOwner=owner_id)
                bucket.delete(ExpectedBucketOwner=owner_id)


if __name__ == "__main__":
    main(sys.argv[1:])



