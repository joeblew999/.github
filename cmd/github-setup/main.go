package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"text/template"
)

type Config struct {
	GitHubOrg string
}

func main() {
	org := flag.String("org", "", "GitHub organization name")
	templateDir := flag.String("templates", "templates", "Template directory")
	outputDir := flag.String("output", ".github", "Output directory")
	flag.Parse()

	if *org == "" {
		log.Fatal("GitHub organization name is required (-org flag)")
	}

	config := Config{GitHubOrg: *org}

	fmt.Printf("Processing templates for organization: %s\n", *org)

	err := filepath.Walk(*templateDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories
		if info.IsDir() {
			return nil
		}

		// Skip non-template files (optional: could filter by extension)
		fmt.Printf("Processing: %s\n", path)

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

		fmt.Printf("  → %s\n", outPath)
		return nil
	})

	if err != nil {
		log.Fatalf("Template processing failed: %v", err)
	}

	fmt.Println("✅ Template processing complete!")
}
