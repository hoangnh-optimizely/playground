package ci

_#mainBranch:       "main"
_#runner:           "ubuntu-latest"
_#pulumiBackendURL: "${{ secrets.PULUMI_CLOUD_URL }}"

_#commonSteps: [
	{uses: "actions/checkout@v4"},
	{
		uses: "aws-actions/configure-aws-credentials@v4"
		with: {
			"role-to-assume": "${{ secrets.AWS_ROLE_TO_ASSUME }}"
			"aws-region":     "us-east-1"
		}
	},
	{
		uses: "actions/setup-go@v4"
		with: "go-version": ">=1.20"
	},
	{run: "go mod download"},
]

_#pulumiStep: {
	uses: "pulumi/actions@v4"
	with: {
		"stack-name": "go"
		"cloud-url":  _#pulumiBackendURL
		command:      string
		diff?:        bool
	}
}

on: {
	push: branches: [_#mainBranch]
	pull_request: branches: [_#mainBranch]
}

permissions: {
	"id-token": "write"
	contents:   "read"
}

env: {
	PULUMI_BACKEND_URL:       _#pulumiBackendURL
	PULUMI_SKIP_UPDATE_CHECK: "true"
}

jobs: plan: {
	name:      "Preview infrastructure changes"
	"if":      "github.event_name == 'pull_request'"
	"runs-on": _#runner
	steps:     _#commonSteps + [ _#pulumiStep & {
		with: {
			command: "preview"
			diff:    true
		}
	}]
}

jobs: up: {
	name:      "Deploy infrastructure"
	"if":      "github.ref == 'refs/heads/" + _#mainBranch + "'"
	"runs-on": _#runner
	steps:     _#commonSteps + [_#pulumiStep & {with: command: "up"}]
}
