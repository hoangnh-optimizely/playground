package main

import (
	"tool/http"
	"tool/exec"
)

command: "vendor-workflow-schema": {
	$short: "Vendor GitHub Workflow schema"

	getSchema: http.Get & {
		url: "https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/schemas/json/github-workflow.json"
	}

	writeCUE: exec.Run & {
		cmd:   "cue import -f -p schemastore -l #Workflow: -o ./cue.mod/pkg/github.com/SchemaStore/schemastore/workflow.cue jsonschema: -"
		stdin: getSchema.response.body
	}
}
