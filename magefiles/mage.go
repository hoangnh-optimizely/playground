package main

import (
	"runtime"

	"github.com/magefile/mage/mg"
)

type (
	Workflow mg.Namespace
	Tofu     mg.Namespace
	Pulumi   mg.Namespace
)

var Default = Workflow.Gen

// filepath of the running process (don't work with -trimpath)
var callerPath = func() string {
	_, f, _, _ := runtime.Caller(0)
	return f
}()
