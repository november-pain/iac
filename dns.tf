# DNS config
# get publicly configured hosted zone on route53
data "aws_route53_zone" "dns" {
  provider = aws.region-master
  name     = var.dns-name
}

# create record in hosted zone for acm certificate domain verification
resource "aws_route53_record" "cert_validation" {
  provider = aws.region-master
  for_each = {
    for value in aws_acm_certificate.jenkins-lb-https.domain_validation_options : value.domain_name => {
      name   = value.resource_record_name
      record = value.resource_record_value
      type   = value.resource_record_type
    }
  }
  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  ttl     = 60
  zone_id = data.aws_route53_zone.dns.zone_id
}

# create alias record towards alb from route53
resource "aws_route53_record" "jenkins" {
  provider = aws.region-master
  zone_id  = data.aws_route53_zone.dns.zone_id
  name     = join(".", ["jenkins", data.aws_route53_zone.dns.name])
  type     = "A"
  alias {
    name                   = aws_lb.application-lb.dns_name
    zone_id                = aws_lb.application-lb.zone_id
    evaluate_target_health = true
  }
}

