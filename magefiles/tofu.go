package main

import (
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

var tofuDir = filepath.Join(callerPath, "../internal/tofu")

// Generate Terraform configuration from CUE source files
func (Tofu) Gen() error {
	return nil
}

// Execute specified Terraform command
func (Tofu) Run(command string) error {
	mg.SerialDeps(Tofu.Gen)

	// FIXME: mage doesn't support variadic arguments in targets yet.
	// Ref: https://github.com/magefile/mage/issues/340
	parsedCmd := strings.Split(command, " ")

	// Ensure we're inside the correct directory before doing anything
	parsedCmd = append([]string{"-chdir=" + tofuDir}, parsedCmd...)

	tofuCmd, err := exec.LookPath("terraform")
	if err != nil {
		return err
	}

	return sh.RunV(tofuCmd, parsedCmd...)
}
