resource "aws_route53_zone" "private" {
  name = "database.darwinbox.local"

  vpc {
    vpc_id = module.db-vpc.vpc_id
  }
}
resource "aws_route53_record" "example_record" {
  count = 3
  zone_id = aws_route53_zone.private.zone_id
  name    = "mongodb-${count.index + 1}.database.darwinbox.local"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mongodb_instance[count.index].private_ip]
}

