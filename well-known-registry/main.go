package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
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
		RunE:  collectFromSources,
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

	// Validate JSON syntax first
	var jsonData interface{}
	if err := json.Unmarshal(registryData, &jsonData); err != nil {
		return fmt.Errorf("invalid JSON syntax: %w", err)
	}
	fmt.Println("✅ JSON syntax valid")

	// Basic validation checks
	var registry map[string]interface{}
	json.Unmarshal(registryData, &registry)

	metadata := registry["metadata"].(map[string]interface{})
	endpoints := registry["endpoints"].(map[string]interface{})

	declaredCount := int(metadata["total_endpoints"].(float64))
	actualCount := len(endpoints)

	if declaredCount != actualCount {
		return fmt.Errorf("endpoint count mismatch: declared %d, actual %d", declaredCount, actualCount)
	}
	fmt.Printf("✅ Endpoint count matches: %d\n", actualCount)

	fmt.Println("\n🎉 All validations passed!")
	return nil
}

func generateCode(cmd *cobra.Command, args []string) error {
	fmt.Println("🔧 Generating Documentation")
	fmt.Println("====================================")

	// Create output directory
	outputPath := filepath.Join(registryDir, outputDir)
	if err := os.MkdirAll(outputPath, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	// Load registry data for documentation generation
	dataPath := filepath.Join(registryDir, dataDir, "well-known-endpoints.json")
	registryData, err := os.ReadFile(dataPath)
	if err != nil {
		return fmt.Errorf("failed to read registry: %w", err)
	}

	var registry map[string]interface{}
	if err := json.Unmarshal(registryData, &registry); err != nil {
		return fmt.Errorf("failed to parse registry: %w", err)
	}

	// Generate API format (minified JSON)
	fmt.Println("📦 Generating API format...")
	apiData, err := json.Marshal(registry)
	if err != nil {
		return fmt.Errorf("failed to marshal API data: %w", err)
	}

	apiPath := filepath.Join(outputPath, "api.json")
	if err := os.WriteFile(apiPath, apiData, 0644); err != nil {
		return fmt.Errorf("failed to write API format: %w", err)
	}
	fmt.Printf("✅ API format generated: %s\n", apiPath)

	// Generate documentation
	fmt.Println("📚 Generating documentation...")
	docs := generateDocumentation(registry)

	docsPath := filepath.Join(outputPath, "docs.md")
	if err := os.WriteFile(docsPath, []byte(docs), 0644); err != nil {
		return fmt.Errorf("failed to write documentation: %w", err)
	}
	fmt.Printf("✅ Documentation generated: %s\n", docsPath)

	fmt.Println("\n🎉 Generation complete!")
	return nil
}

func showStats(cmd *cobra.Command, args []string) error {
	dataPath := filepath.Join(registryDir, dataDir, "well-known-endpoints.json")
	registryData, err := os.ReadFile(dataPath)
	if err != nil {
		return fmt.Errorf("failed to read registry: %w", err)
	}

	var registry map[string]interface{}
	if err := json.Unmarshal(registryData, &registry); err != nil {
		return fmt.Errorf("failed to parse registry: %w", err)
	}

	metadata := registry["metadata"].(map[string]interface{})
	endpoints := registry["endpoints"].(map[string]interface{})

	fmt.Println("📊 Registry Statistics")
	fmt.Println("======================")
	fmt.Printf("📦 Total Endpoints: %v\n", metadata["total_endpoints"])
	fmt.Printf("📅 Last Updated: %v\n", metadata["last_updated"])
	fmt.Printf("🔢 Version: %v\n", metadata["version"])
	fmt.Printf("📋 Actual Endpoints: %d\n", len(endpoints))

	fmt.Println("\n📋 Endpoints by Category:")
	categoryCount := make(map[string]int)
	for _, endpoint := range endpoints {
		ep := endpoint.(map[string]interface{})
		category := ep["category"].(string)
		categoryCount[category]++
	}
	for category, count := range categoryCount {
		fmt.Printf("  • %s: %d\n", category, count)
	}

	fmt.Println("\n🔍 Authority Levels:")
	authCounts := make(map[string]int)
	for _, endpoint := range endpoints {
		ep := endpoint.(map[string]interface{})
		level := ep["authority_level"].(string)
		authCounts[level]++
	}
	for level, count := range authCounts {
		fmt.Printf("  • %s: %d\n", level, count)
	}

	return nil
}

func collectFromSources(cmd *cobra.Command, args []string) error {
	fmt.Println("🔄 Collecting from Sources")
	fmt.Println("==========================")
	fmt.Println("🚧 Collection from external sources coming soon!")
	fmt.Println("💡 Will collect from:")
	fmt.Println("   • IANA Registry")
	fmt.Println("   • awesome-well-known")
	fmt.Println("   • Browser documentation")
	fmt.Println("   • RFC specifications")
	return nil
}

func generateDocumentation(registry map[string]interface{}) string {
	var docs strings.Builder

	docs.WriteString("# Well-Known Endpoints Registry - Generated Documentation\n\n")
	docs.WriteString("This documentation is auto-generated from the registry data.\n\n")

	metadata := registry["metadata"].(map[string]interface{})

	docs.WriteString("## Statistics\n\n")
	docs.WriteString(fmt.Sprintf("- **Total Endpoints**: %v\n", metadata["total_endpoints"]))
	docs.WriteString(fmt.Sprintf("- **Version**: %v\n", metadata["version"]))
	docs.WriteString(fmt.Sprintf("- **Last Updated**: %v\n", metadata["last_updated"]))
	docs.WriteString("\n")

	// All endpoints
	docs.WriteString("## All Endpoints\n\n")
	endpoints := registry["endpoints"].(map[string]interface{})
	for name, endpoint := range endpoints {
		ep := endpoint.(map[string]interface{})
		docs.WriteString(fmt.Sprintf("### %s\n\n", name))
		docs.WriteString(fmt.Sprintf("- **Path**: `%s`\n", ep["path"]))
		docs.WriteString(fmt.Sprintf("- **Method**: %s\n", ep["method"]))
		docs.WriteString(fmt.Sprintf("- **Category**: %s\n", ep["category"]))
		docs.WriteString(fmt.Sprintf("- **Authority**: %s\n", ep["authority_level"]))
		docs.WriteString(fmt.Sprintf("- **Status**: %s\n", ep["verification_status"]))

		if browserSupport, ok := ep["browser_support"]; ok {
			browsers := browserSupport.([]interface{})
			browserNames := make([]string, len(browsers))
			for i, browser := range browsers {
				browserNames[i] = browser.(string)
			}
			docs.WriteString(fmt.Sprintf("- **Browser Support**: %s\n", strings.Join(browserNames, ", ")))
		}

		docs.WriteString(fmt.Sprintf("\n%s\n\n", ep["description"]))
	}

	docs.WriteString(fmt.Sprintf("---\n*Generated at %s*\n", time.Now().Format(time.RFC3339)))

	return docs.String()
}
