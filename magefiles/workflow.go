//go:build mage
// +build mage

package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/encoding/yaml"
	"github.com/magefile/mage/sh"
)

var workflowSchemaPath = "../cue.mod/pkg/github.com/SchemaStore/schemastore/src/schemas/json/github-workflow.cue"

var ctx = cuecontext.New()

// Generate GitHub Actions workflow definitions
func (Workflow) Gen() error {
	// Get a stable file path
	// NOTE: don't work with -trimpath
	_, f, _, _ := runtime.Caller(0)

	outputDir := filepath.Join(filepath.Dir(f), "../.github/workflows")
	inputDir := filepath.Join(filepath.Dir(f), "../internal/ci")
	entries, err := os.ReadDir(inputDir)
	if err != nil {
		return err
	}

	// Read the schema file for YAML validation
	workflowSchemaData, err := os.ReadFile(filepath.Join(filepath.Dir(f), workflowSchemaPath))
	if err != nil {
		return err
	}
	workflowSchema := ctx.CompileBytes(workflowSchemaData)
	if workflowSchema.Err() != nil {
		return workflowSchema.Err()
	}

	// Run things in parallel so it's a bit faster
	var wg sync.WaitGroup

	// Where did you copy this pattern from?
	// https://www.golangcode.com/errors-in-waitgroups/
	wgDone := make(chan struct{})
	errs := make(chan error)

	for _, entry := range entries {
		entry := entry // The infamous "out of loop" value access thing
		wg.Add(1)

		go func() {
			defer wg.Done()

			entryExt := filepath.Ext(entry.Name())

			// Each *.cue file in this directory is corresponding to a workflow definition file
			if !entry.IsDir() && entryExt == ".cue" {
				inputCueBytes, err := os.ReadFile(filepath.Join(inputDir, entry.Name()))
				if err != nil {
					errs <- err
				}

				inputCue := ctx.CompileBytes(inputCueBytes)
				if inputCue.Err() != nil {
					errs <- fmt.Errorf("%s: %v", entry.Name(), inputCue.Err())
				}

				// Transform CUE input to YAML
				result, err := yaml.Encode(inputCue)
				if err != nil {
					errs <- fmt.Errorf("%s: %v", entry.Name(), err)
				}

				// Validate CI configuration against GitHub Workflow JSONSchema
				err = yaml.Validate(result, workflowSchema.LookupPath(cue.ParsePath("#Workflow")))
				if err != nil {
					errs <- fmt.Errorf("%s: %v", entry.Name(), err)
				}

				baseFileName := strings.TrimSuffix(entry.Name(), entryExt)
				err = os.WriteFile(filepath.Join(outputDir, baseFileName+".yml"), result, 0o644)
				if err != nil {
					errs <- err
				}
			}
		}()
	}

	// Start a final goroutine to wait for every function to finish
	go func() {
		wg.Wait()
		close(wgDone)
	}()

	// Wait for either WaitGroup is done or an error is received
	select {
	case <-wgDone:
		break
	case err := <-errs:
		close(errs)
		return err
	}

	return nil
}

// Generate CUE schema file based on the JSON schema of github-workflow
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
	_, f, _, _ := runtime.Caller(0)
	outputPath := filepath.Join(filepath.Dir(f), workflowSchemaPath)

	// Ensure the parent directory exists before writing a file into it
	err = os.MkdirAll(filepath.Dir(outputPath), 0o755)
	if err != nil {
		return fmt.Errorf("failed to create workflow CUE package directory: %v", err)
	}

	// Write the retrieved jsonschema to a temporary file (we'll rm it afterward)
	tmpJsonschemaPath := "/tmp/github-workflow.json"
	err = os.WriteFile(tmpJsonschemaPath, workflowSchemaBytes, 0o644)
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
