package rds

import "encoding/json"

result: resource: {
	aws_iam_policy: rds: {
		name:        "iam-db-auth-test"
		description: "Test IAM policy to access RDS instance via IAM authentication"
		policy: json.Marshal({
			Version: "2012-10-17"
			Statement: [
				{
					Effect: "Allow"
					Action: ["rds-db:connect"]
					Resource: [
						"arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.rds.resource_id}/${mysql_user.iam_user.user}",
					]
				},
			]
		})
	}

	aws_iam_role: rds: {
		name: "iam-db-auth-test"
		assume_role_policy: json.Marshal({
			Version: "2012-10-17"
			Statement: [
				{
					Action: "sts:AssumeRole"
					Effect: "Allow"
					Sid:    ""
					Principal: AWS: "${data.aws_caller_identity.current.account_id}"
				},
			]
		})
	}

	aws_iam_role_policy_attachment: rds: {
		role:       "${aws_iam_role.rds.name}"
		policy_arn: "${aws_iam_policy.rds.arn}"
	}
}
