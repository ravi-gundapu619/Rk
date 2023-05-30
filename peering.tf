resource "aws_vpc_peering_connection" "vpc-peering" {
  vpc_id   = "${module.main-vpc.vpc_id}"
  peer_vpc_id   = "${module.db-vpc.vpc_id}"
  auto_accept   = true
  

  accepter {
  allow_remote_vpc_dns_resolution = true

  }
  requester {
  allow_remote_vpc_dns_resolution = true

  }
}
resource "aws_route" "vpc-peering-route-main-vpc" {
  route_table_id = "${module.main-vpc.public_route_table_ids[0]}"
  destination_cidr_block = module.db-vpc.vpc_cidr_block
  vpc_peering_connection_id = "${aws_vpc_peering_connection.vpc-peering.id}"
}

resource "aws_route" "vpc-peering-route-db-vpc" {
  route_table_id = "${module.db-vpc.public_route_table_ids[0]}"
  destination_cidr_block = module.main-vpc.vpc_cidr_block
  vpc_peering_connection_id = "${aws_vpc_peering_connection.vpc-peering.id}"
}








