package rds

import "github.com/hoangnh-optimizely/playground/internal/tofu"

result: tofu.#Base & {
	for _, provider in ["aws", "random", "mysql"] {
		terraform: required_providers: (provider): tofu.providers[provider]
	}

	provider: aws: region: "us-east-1"
	provider: mysql: {
		endpoint: "${aws_db_instance.rds.endpoint}"
		username: "${aws_db_instance.rds.username}"
		password: "${aws_db_instance.rds.password}"
	}
}
