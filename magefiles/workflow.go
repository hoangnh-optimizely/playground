// SPDX-FileCopyrightText: 2023 Hoang Nguyen <folliekazetani@protonmail.com>
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/encoding/yaml"
	"github.com/magefile/mage/sh"
	"golang.org/x/sync/errgroup"
)

var workflowSchemaPath = "../cue.mod/pkg/github.com/SchemaStore/schemastore/src/schemas/json/github-workflow.cue"

var ctx = cuecontext.New()

// Generate GitHub Actions workflow definitions
func (Workflow) Gen() error {
	inputDir := filepath.Join(callerDir, "../internal/ci")
	entries, err := os.ReadDir(inputDir)
	if err != nil {
		return err
	}

	// Wipe everything and recreate the CI directory (nothing there should be manually managed)
	outputDir := filepath.Join(callerDir, "../.github/workflows")
	err = os.RemoveAll(outputDir)
	if err != nil {
		return err
	}
	if e := os.MkdirAll(outputDir, 0o755); e != nil {
		return e
	}

	// Read the schema file for YAML validation
	workflowSchemaData, err := os.ReadFile(filepath.Join(callerDir, workflowSchemaPath))
	if err != nil {
		return err
	}
	workflowSchema := ctx.CompileBytes(workflowSchemaData)
	if workflowSchema.Err() != nil {
		return workflowSchema.Err()
	}

	errs := new(errgroup.Group)

	// Each *.cue file in this directory is corresponding to a workflow definition file
	for _, entry := range entries {
		entry := entry // https://golang.org/doc/faq#closures_and_goroutines

		errs.Go(func() error {
			entryExt := filepath.Ext(entry.Name())

			if !entry.IsDir() && entryExt == ".cue" {
				inputCueBytes, err := os.ReadFile(filepath.Join(inputDir, entry.Name()))
				if err != nil {
					return err
				}

				inputCue := ctx.CompileBytes(inputCueBytes)
				if inputCue.Err() != nil {
					return fmt.Errorf("%s: %v", entry.Name(), inputCue.Err())
				}

				// Transform CUE input to YAML
				result, err := yaml.Encode(inputCue)
				if err != nil {
					return fmt.Errorf("%s: %v", entry.Name(), err)
				}

				// Validate CI configuration against GitHub Workflow JSONSchema
				err = yaml.Validate(result, workflowSchema.LookupPath(cue.ParsePath("#Workflow")))
				if err != nil {
					return fmt.Errorf("%s: %v", entry.Name(), err)
				}

				outputFile := strings.TrimSuffix(entry.Name(), entryExt) + ".yml"
				err = os.WriteFile(filepath.Join(outputDir, outputFile), result, 0o600)
				if err != nil {
					return err
				}
				fmt.Println("=>", outputFile)
			}

			return nil
		})
	}

	return errs.Wait()
}

// Generate CUE schema file based on the jsonschema of github-workflow
func (Workflow) Schema() error {
	// FIXME: the generated schema doesn't actually work due to duplicated keys `uses` and `run` in steps definitions.
	// The schema file inside this repo was tweaked a little to make us all happy ^-^

	res, err := http.Get("https://json.schemastore.org/github-workflow.json")
	if err != nil {
		return fmt.Errorf("failed to retrieve github-workflow jsonschema: %v", err)
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to retrieve github-workflow jsonschema: status code %v", res.StatusCode)
	}

	workflowSchemaBytes, err := io.ReadAll(res.Body)
	if err != nil {
		return err
	}

	// Again, to ensure consistent filepath
	outputPath := filepath.Join(callerDir, workflowSchemaPath)

	// Ensure the parent directory exists before writing a file into it
	err = os.MkdirAll(filepath.Dir(outputPath), 0o755)
	if err != nil {
		return fmt.Errorf("failed to create workflow CUE package directory: %v", err)
	}

	// Write the retrieved jsonschema to a temporary file (we'll rm it afterward)
	tmpJsonschemaPath := "/tmp/github-workflow.json"
	err = os.WriteFile(tmpJsonschemaPath, workflowSchemaBytes, 0o600)
	if err != nil {
		return err
	}
	defer os.Remove(tmpJsonschemaPath)

	cueBin, err := exec.LookPath("cue")
	if err != nil {
		return err
	}

	return sh.RunV(
		cueBin,
		"import",
		"-f",
		"-p=json",
		"-l=#Workflow:",
		"-o="+outputPath,
		tmpJsonschemaPath,
	)
}
