package main

import "github.com/magefile/mage/mg"

type (
	Workflow mg.Namespace
	Tofu     mg.Namespace
)

var Default = Workflow.Gen
