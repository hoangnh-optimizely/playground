package main

import (
	"list"
	"tool/exec"
)

command: tofu: {
	$short: "Thin wrapper over Tofu command"

	// Inject arguments to the task
	action: *"init" | "plan" | "apply" @tag(action)
	stack:  string                     @tag(stack)

	// Only allow running tofu on OpenTofu projects, obviously
	_tofuStacks: ["rds"]
	_tofuStacks: list.Contains(stack)

	gen: exec.Run & {
		cmd: ["cue", "export", "--force", "--outfile", "main.tf.json"]
		dir: "./stacks/\(stack)"
	}

	run: exec.Run & {
		$after: gen

		cmd: ["tofu", action, if action == "apply" {"-auto-approve"}]
		dir: "./stacks/\(stack)"
	}
}
