package rds

import "github.com/hoangnh-optimizely/playground/internal/tofu"

// Ref: https://github.com/hashicorp/learn-terraform-rds
result: {
	resource: {
		random_password: rds: {
			length:           24
			special:          true
			override_special: "!#$%&*()-_=+[]{}<>:?"
		}

		aws_db_instance: rds: {
			identifier:                          "iam-db-auth-test"
			instance_class:                      "db.t3.micro"
			allocated_storage:                   5
			engine:                              "mariadb"
			engine_version:                      "10.11"
			username:                            "admin"
			password:                            "${random_password.rds.result}"
			db_subnet_group_name:                "${aws_db_subnet_group.rds.id}"
			parameter_group_name:                "default.mariadb10.11"
			skip_final_snapshot:                 true
			publicly_accessible:                 true
			iam_database_authentication_enabled: true
			vpc_security_group_ids: ["${aws_security_group.rds.id}"]
		}

		mysql_user: iam_user: {
			user:        "iam_user"
			host:        "%"
			auth_plugin: "AWSAuthenticationPlugin"
			tls_option:  "SSL"
		}
	}

	output: {
		db_password: {
			value:     "${random_password.rds.result}"
			sensitive: true
		}
		db_url: value: "${aws_db_instance.rds.address}"
	}
}
