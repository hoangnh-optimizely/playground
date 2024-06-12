package tofu

#Base: {
	terraform: {
		required_version: "~> 1.7.0"

		required_providers?: #Providers
	}

	provider?: [string]: {...}

	module?: [string]: {...}

	resource?: [string]: [=~"^[a-zA-Z0-9_]+$"]: {...}

	data?: [string]: [=~"^[a-zA-Z0-9_]+$"]: {...}

	output?: [string]: {...}
}
