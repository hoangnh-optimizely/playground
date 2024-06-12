package tofu

#Providers: [string]: {
	source:  string
	version: string
}

providers: #Providers & {
	aws: {
		source:  "hashicorp/aws"
		version: "5.53.0"
	}

	random: {
		source:  "opentofu/random"
		version: "3.6.2"
	}
}
