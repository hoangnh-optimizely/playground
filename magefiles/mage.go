// SPDX-FileCopyrightText: 2023 Hoang Nguyen <folliekazetani@protonmail.com>
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"path/filepath"
	"runtime"

	"github.com/magefile/mage/mg"
)

type (
	Workflow mg.Namespace
	Tofu     mg.Namespace
	Pulumi   mg.Namespace
)

var Default = Workflow.Gen

// Directory contains the source file of the running process (don't work with -trimpath)
var callerDir = func() string {
	_, f, _, _ := runtime.Caller(0)
	return filepath.Dir(f)
}()
