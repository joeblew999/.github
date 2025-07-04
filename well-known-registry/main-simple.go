package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

var (
	registryDir = "."
	dataDir     = "data"
	schemasDir  = "schemas"
	outputDir   = "generated"
)

type Registry struct {
	Metadata  Metadata            `json:"metadata"`
	Endpoints map[string]Endpoint `json:"endpoints"`
}

type Metadata struct {
	Name           string    `json:"name"`
	Description    string    `json:"description"`
	Version        string    `json:"version"`
	LastUpdated    time.Time `json:"last_updated"`
	TotalEndpoints int       `json:"total_endpoints"`
	Sources        []Source  `json:"sources"`
}

type Source struct {
	Name string `json:"name"`
	URL  string `json:"url"`
	Type string `json:"type"`
}

type Endpoint struct {
	Name           string            `json:"name"`
	Path           string            `json:"path"`
	Description    string            `json:"description"`
	Category       string            `json:"category"`
	Status         string            `json:"status"`
	Authority      string            `json:"authority"`
	Verification   string            `json:"verification"`
	Sources        []EndpointSource  `json:"sources"`
	BrowserSupport map[string]string `json:"browser_support,omitempty"`
}

type EndpointSource struct {
	URL         string    `json:"url"`
	CollectedAt time.Time `json:"collected_at"`
	Authority   string    `json:"authority"`
}

func main() {
	var rootCmd = &cobra.Command{
		Use:   "well-known-registry",
		Short: "Well-Known Endpoints Registry Management Tool",
		Long:  "Validate, generate, and manage the well-known endpoints registry with full provenance tracking.",
	}

	// Validate command
	var validateCmd = &cobra.Command{
		Use:   "validate",
		Short: "Validate registry data",
		RunE:  validateRegistry,
	}

	// Generate command
	var generateCmd = &cobra.Command{
		Use:   "generate",
		Short: "Generate documentation",
		RunE:  generateCode,
	}

	// Stats command
	var statsCmd = &cobra.Command{
		Use:   "stats",
		Short: "Show registry statistics",
		RunE:  showStats,
	}

	// Collect command (placeholder for future source collection)
	var collectCmd = &cobra.Command{
		Use:   "collect",
		Short: "Collect endpoints from sources",
		RunE:  collectEndpoints,
	}

	rootCmd.AddCommand(validateCmd, generateCmd, statsCmd, collectCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func validateRegistry(cmd *cobra.Command, args []string) error {
	fmt.Println("🔍 Validating Well-Known Endpoints Registry")
	fmt.Println("===========================================")

	// Load registry data
	dataPath := filepath.Join(registryDir, dataDir, "well-known-endpoints.json")
	registryData, err := os.ReadFile(dataPath)
	if err != nil {
		return fmt.Errorf("failed to read registry: %w", err)
	}

	// Validate JSON syntax
	var registry Registry
	if err := json.Unmarshal(registryData, &registry); err != nil {
		return fmt.Errorf("invalid JSON syntax: %w", err)
	}
	fmt.Println("✅ JSON syntax valid")

	// Basic validation checks
	if registry.Metadata.Name == "" {
		return fmt.Errorf("metadata.name is required")
	}

	if len(registry.Endpoints) == 0 {
		return fmt.Errorf("no endpoints defined")
	}

	// Check endpoint count consistency
	if registry.Metadata.TotalEndpoints != len(registry.Endpoints) {
		return fmt.Errorf("endpoint count mismatch: declared %d, actual %d",
			registry.Metadata.TotalEndpoints, len(registry.Endpoints))
	}
	fmt.Printf("✅ Endpoint count matches: %d\n", len(registry.Endpoints))

	// Validate individual endpoints
	for name, endpoint := range registry.Endpoints {
		if endpoint.Name == "" {
			return fmt.Errorf("endpoint %s: name is required", name)
		}
		if endpoint.Path == "" {
			return fmt.Errorf("endpoint %s: path is required", name)
		}
		if !strings.HasPrefix(endpoint.Path, "/.well-known/") {
			return fmt.Errorf("endpoint %s: path must start with /.well-known/", name)
		}
	}
	fmt.Printf("✅ All %d endpoints valid\n", len(registry.Endpoints))

	fmt.Println("\n🎉 All validations passed!")
	return nil
}

func generateCode(cmd *cobra.Command, args []string) error {
	fmt.Println("🔧 Generating Documentation")
	fmt.Println("===========================")

	// Create output directory
	outputPath := filepath.Join(registryDir, outputDir)
	if err := os.MkdirAll(outputPath, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	// Load registry data
	dataPath := filepath.Join(registryDir, dataDir, "well-known-endpoints.json")
	registryData, err := os.ReadFile(dataPath)
	if err != nil {
		return fmt.Errorf("failed to read registry: %w", err)
	}

	var registry Registry
	if err := json.Unmarshal(registryData, &registry); err != nil {
		return fmt.Errorf("failed to parse registry: %w", err)
	}

	// Generate documentation
	fmt.Println("📝 Generating documentation...")
	docContent := generateDocumentation(registry)
	docPath := filepath.Join(outputPath, "docs.md")
	if err := os.WriteFile(docPath, []byte(docContent), 0644); err != nil {
		return fmt.Errorf("failed to write documentation: %w", err)
	}
	fmt.Printf("✅ Documentation written to %s\n", docPath)

	// Generate API format
	fmt.Println("🔧 Generating API format...")
	apiContent, err := json.MarshalIndent(registry, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal API data: %w", err)
	}
	apiPath := filepath.Join(outputPath, "api.json")
	if err := os.WriteFile(apiPath, apiContent, 0644); err != nil {
		return fmt.Errorf("failed to write API format: %w", err)
	}
	fmt.Printf("✅ API format written to %s\n", apiPath)

	fmt.Println("\n🎉 Generation complete!")
	return nil
}

func showStats(cmd *cobra.Command, args []string) error {
	fmt.Println("📊 Well-Known Endpoints Registry Statistics")
	fmt.Println("==========================================")

	// Load registry data
	dataPath := filepath.Join(registryDir, dataDir, "well-known-endpoints.json")
	registryData, err := os.ReadFile(dataPath)
	if err != nil {
		return fmt.Errorf("failed to read registry: %w", err)
	}

	var registry Registry
	if err := json.Unmarshal(registryData, &registry); err != nil {
		return fmt.Errorf("failed to parse registry: %w", err)
	}

	// General stats
	fmt.Printf("Registry: %s v%s\n", registry.Metadata.Name, registry.Metadata.Version)
	fmt.Printf("Last Updated: %s\n", registry.Metadata.LastUpdated.Format("2006-01-02"))
	fmt.Printf("Total Endpoints: %d\n", len(registry.Endpoints))
	fmt.Printf("Data Sources: %d\n\n", len(registry.Metadata.Sources))

	// Category breakdown
	categories := make(map[string]int)
	authorities := make(map[string]int)
	statuses := make(map[string]int)

	for _, endpoint := range registry.Endpoints {
		categories[endpoint.Category]++
		authorities[endpoint.Authority]++
		statuses[endpoint.Status]++
	}

	fmt.Println("📂 By Category:")
	for category, count := range categories {
		fmt.Printf("  %s: %d\n", category, count)
	}

	fmt.Println("\n🏛️  By Authority:")
	for authority, count := range authorities {
		fmt.Printf("  %s: %d\n", authority, count)
	}

	fmt.Println("\n📋 By Status:")
	for status, count := range statuses {
		fmt.Printf("  %s: %d\n", status, count)
	}

	return nil
}

func collectEndpoints(cmd *cobra.Command, args []string) error {
	fmt.Println("🔄 Collecting endpoints from sources")
	fmt.Println("====================================")
	fmt.Println("⚠️  Collection feature not yet implemented")
	fmt.Println("Future: Will collect from IANA, awesome-well-known, etc.")
	return nil
}

func generateDocumentation(registry Registry) string {
	var doc strings.Builder

	doc.WriteString(fmt.Sprintf("# %s\n\n", registry.Metadata.Name))
	doc.WriteString(fmt.Sprintf("%s\n\n", registry.Metadata.Description))
	doc.WriteString(fmt.Sprintf("**Version:** %s  \n", registry.Metadata.Version))
	doc.WriteString(fmt.Sprintf("**Last Updated:** %s  \n", registry.Metadata.LastUpdated.Format("2006-01-02")))
	doc.WriteString(fmt.Sprintf("**Total Endpoints:** %d\n\n", len(registry.Endpoints)))

	// Group by category
	categories := make(map[string][]string)
	for name, endpoint := range registry.Endpoints {
		categories[endpoint.Category] = append(categories[endpoint.Category], name)
	}

	// Sort categories and endpoints
	var categoryNames []string
	for category := range categories {
		categoryNames = append(categoryNames, category)
		sort.Strings(categories[category])
	}
	sort.Strings(categoryNames)

	doc.WriteString("## Endpoints by Category\n\n")
	for _, category := range categoryNames {
		doc.WriteString(fmt.Sprintf("### %s\n\n", strings.Title(category)))

		for _, name := range categories[category] {
			endpoint := registry.Endpoints[name]
			doc.WriteString(fmt.Sprintf("#### `%s`\n\n", endpoint.Path))
			doc.WriteString(fmt.Sprintf("**Name:** %s  \n", endpoint.Name))
			doc.WriteString(fmt.Sprintf("**Description:** %s  \n", endpoint.Description))
			doc.WriteString(fmt.Sprintf("**Status:** %s  \n", endpoint.Status))
			doc.WriteString(fmt.Sprintf("**Authority:** %s  \n", endpoint.Authority))

			if len(endpoint.Sources) > 0 {
				doc.WriteString("**Sources:**\n")
				for _, source := range endpoint.Sources {
					doc.WriteString(fmt.Sprintf("- [%s](%s)\n", source.Authority, source.URL))
				}
			}
			doc.WriteString("\n")
		}
	}

	doc.WriteString("## Data Sources\n\n")
	for _, source := range registry.Metadata.Sources {
		doc.WriteString(fmt.Sprintf("- **%s** (%s): [%s](%s)\n", source.Name, source.Type, source.URL, source.URL))
	}

	return doc.String()
}
