package main

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/magefile/mage/sh"
	"golang.org/x/exp/slices"
)

var pulumiStackPaths = map[string]string{
	"go":  filepath.Join(callerDir, ".."),
	"cue": filepath.Join(callerDir, "../internal/pulumi-cue"),
}

// Execute specified Pulumi command
func (Pulumi) Run(stack, command string) error {
	stacks := []string{}
	for stack := range pulumiStackPaths {
		stacks = append(stacks, stack)
	}

	if !slices.Contains(stacks, stack) {
		return fmt.Errorf("Pulumi stack %s doesn't exist in the project", stack)
	}

	parsedCmd := strings.Split(command, " ")

	// Ensure we're inside the correct directory before doing anything
	parsedCmd = append(parsedCmd, "--cwd="+pulumiStackPaths[stack])

	pulumiCmd, err := exec.LookPath("pulumi")
	if err != nil {
		return err
	}

	err = sh.RunV(pulumiCmd, "stack", "select", stack)
	if err != nil {
		return err
	}

	// Run the defined Pulumi command with sh.RunV
	return sh.RunV(pulumiCmd, parsedCmd...)
}
