output "jenkins-master-node-pub-ip" {
  value = aws_instance.jenkins-master.public_ip
}

output "jenkins-worker-pub-ips" {
  value = {
    for instance in aws_instance.jenkins-worker-oregon :
    instance.id => instance.public_ip
  }
}

output "alb-dns-name" {
  value = aws_lb.application-lb.dns_name
}

output "url" {
  value = aws_route53_record.jenkins.fqdn
}

