package rds

import "github.com/hoangnh-optimizely/playground/internal/tofu"

result: {
	data: {
		aws_availability_zones: avaiable: {}
		aws_region: current: {}
		aws_caller_identity: current: {}
	}

	module: vpc: tofu.modules.vpc & {
		name: "iam-db-auth-test"
		cidr: "10.0.0.0/16"
		azs:  "${data.aws_availability_zones.avaiable.names}"
		public_subnets: ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
	}

	resource: {
		aws_security_group: rds: {
			name:   "iam-db-auth-test"
			vpc_id: "${module.vpc.vpc_id}"

			tags: {
				Name: "iam-db-auth-test"
			}
		}

		for _, type in ["ingress", "egress"] {
			"aws_vpc_security_group_\(type)_rule": rds: {
				security_group_id: "${aws_security_group.rds.id}"
				cidr_ipv4:         "0.0.0.0/0"
				from_port:         "${aws_db_instance.rds.port}"
				to_port:           "${aws_db_instance.rds.port}"
				ip_protocol:       "tcp"
			}
		}

		aws_db_subnet_group: rds: {
			name:       "iam-db-auth-test"
			subnet_ids: "${module.vpc.public_subnets}"

			tags: {
				Name: "iam-db-auth-test"
			}
		}
	}
}
