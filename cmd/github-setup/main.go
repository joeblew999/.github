package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"text/template"
)

const version = "1.0.0"

type Config struct {
	GitHubOrg string
}

func main() {
	org := flag.String("org", "", "GitHub organization name")
	templateDir := flag.String("templates", "templates", "Template directory")
	outputDir := flag.String("output", ".github", "Output directory")
	versionFlag := flag.Bool("version", false, "Show version and exit")
	verbose := flag.Bool("verbose", false, "Verbose output")
	flag.Parse()

	if *versionFlag {
		fmt.Printf("github-setup version %s\n", version)
		os.Exit(0)
	}

	if *org == "" {
		log.Fatal("GitHub organization name is required (-org flag)")
	}

	config := Config{GitHubOrg: *org}

	if *verbose {
		fmt.Printf("Processing templates for organization: %s\n", *org)
		fmt.Printf("Template directory: %s\n", *templateDir)
		fmt.Printf("Output directory: %s\n", *outputDir)
	} else {
		fmt.Printf("Processing templates for organization: %s\n", *org)
	}

	err := filepath.Walk(*templateDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories
		if info.IsDir() {
			return nil
		}

		// Skip non-template files (optional: could filter by extension)
		if *verbose {
			fmt.Printf("Processing: %s\n", path)
		}

		// Parse template
		tmpl, err := template.ParseFiles(path)
		if err != nil {
			return fmt.Errorf("failed to parse template %s: %w", path, err)
		}

		// Calculate output path
		rel, err := filepath.Rel(*templateDir, path)
		if err != nil {
			return fmt.Errorf("failed to get relative path: %w", err)
		}

		outPath := filepath.Join(*outputDir, rel)

		// Create output directory if it doesn't exist
		outDir := filepath.Dir(outPath)
		if err := os.MkdirAll(outDir, 0755); err != nil {
			return fmt.Errorf("failed to create output directory %s: %w", outDir, err)
		}

		// Create output file
		out, err := os.Create(outPath)
		if err != nil {
			return fmt.Errorf("failed to create output file %s: %w", outPath, err)
		}
		defer out.Close()

		// Execute template
		if err := tmpl.Execute(out, config); err != nil {
			return fmt.Errorf("failed to execute template %s: %w", path, err)
		}

		if *verbose {
			fmt.Printf("  → %s\n", outPath)
		}
		return nil
	})

	if err != nil {
		log.Fatalf("Template processing failed: %v", err)
	}

	fmt.Println("✅ Template processing complete!")
}
