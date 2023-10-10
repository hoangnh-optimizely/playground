//go:build mage
// +build mage

package main

import "github.com/magefile/mage/mg"

type Workflow mg.Namespace

var Default = Workflow.Gen
