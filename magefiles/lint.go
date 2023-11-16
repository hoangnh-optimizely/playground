// SPDX-FileCopyrightText: 2023 Hoang Nguyen <folliekazetani@protonmail.com>
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"os/exec"

	"github.com/magefile/mage/sh"
)

// Run golangci-lint on the codebase
func Lint() error {
	golangci, err := exec.LookPath("golangci-lint")
	if err != nil {
		return err
	}

	return sh.RunV(golangci, "run")
}
