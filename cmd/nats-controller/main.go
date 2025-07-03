package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

const version = "1.0.0"

// NATSConfig holds NATS connection configuration
type NATSConfig struct {
	URLs            []string `json:"urls"`
	CredsFile       string   `json:"creds_file,omitempty"`
	NKeyFile        string   `json:"nkey_file,omitempty"`
	JWT             string   `json:"jwt,omitempty"`
	NKeySeed        string   `json:"nkey_seed,omitempty"`
	TLSEnabled      bool     `json:"tls_enabled"`
	TLSInsecure     bool     `json:"tls_insecure"`
	TLSCertFile     string   `json:"tls_cert_file,omitempty"`
	TLSKeyFile      string   `json:"tls_key_file,omitempty"`
	TLSCAFile       string   `json:"tls_ca_file,omitempty"`
	MaxReconnect    int      `json:"max_reconnect"`
	ReconnectWait   int      `json:"reconnect_wait_seconds"`
	Timeout         int      `json:"timeout_seconds"`
	JetStreamDomain string   `json:"jetstream_domain,omitempty"`
	Context         string   `json:"context,omitempty"`
	DeploymentType  string   `json:"deployment_type"` // synadia_cloud, self_hosted, hybrid
}

// GitHubEvent represents a GitHub-related event
type GitHubEvent struct {
	Timestamp string                 `json:"timestamp"`
	Org       string                 `json:"org"`
	Repo      string                 `json:"repo"`
	EventType string                 `json:"event_type"`
	Data      map[string]interface{} `json:"data"`
}

// Controller handles GitHub workflow orchestration via NATS
type Controller struct {
	nc       *nats.Conn
	js       jetstream.JetStream
	org      string
	config   *NATSConfig
	subjects map[string]nats.MsgHandler
}

// NewController creates a new workflow controller with flexible NATS configuration
func NewController(org string, config *NATSConfig) (*Controller, error) {
	// Build NATS connection options
	opts := []nats.Option{
		nats.Name(fmt.Sprintf("github-controller-%s", org)),
		nats.MaxReconnects(config.MaxReconnect),
		nats.ReconnectWait(time.Duration(config.ReconnectWait) * time.Second),
		nats.Timeout(time.Duration(config.Timeout) * time.Second),
		nats.DisconnectErrHandler(func(nc *nats.Conn, err error) {
			log.Printf("NATS disconnected: %v", err)
		}),
		nats.ReconnectHandler(func(nc *nats.Conn) {
			log.Printf("NATS reconnected to %s", nc.ConnectedUrl())
		}),
		nats.ClosedHandler(func(nc *nats.Conn) {
			log.Printf("NATS connection closed")
		}),
	}

	// Configure authentication based on deployment type
	switch config.DeploymentType {
	case "synadia_cloud":
		opts = append(opts, configureSynadiaAuth(config)...)
	case "self_hosted", "self_hosted_single", "self_hosted_cluster":
		opts = append(opts, configureSelfHostedAuth(config)...)
	case "hybrid":
		// For hybrid, try Synadia first, fallback to self-hosted
		opts = append(opts, configureSynadiaAuth(config)...)
		opts = append(opts, configureSelfHostedAuth(config)...)
	}

	// Configure TLS if enabled
	if config.TLSEnabled {
		tlsConfig := &tls.Config{
			InsecureSkipVerify: config.TLSInsecure,
		}

		if config.TLSCertFile != "" && config.TLSKeyFile != "" {
			cert, err := tls.LoadX509KeyPair(config.TLSCertFile, config.TLSKeyFile)
			if err != nil {
				return nil, fmt.Errorf("failed to load TLS cert/key: %w", err)
			}
			tlsConfig.Certificates = []tls.Certificate{cert}
		}

		opts = append(opts, nats.Secure(tlsConfig))
	}

	// Connect to NATS
	nc, err := nats.Connect(strings.Join(config.URLs, ","), opts...)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to NATS (%s): %w", config.DeploymentType, err)
	}

	// Create JetStream context
	jsOpts := []jetstream.JetStreamOpt{}
	if config.JetStreamDomain != "" {
		// Note: Domain support may require newer NATS version
		log.Printf("JetStream domain requested: %s", config.JetStreamDomain)
	}

	js, err := jetstream.New(nc, jsOpts...)
	if err != nil {
		return nil, fmt.Errorf("failed to create JetStream context: %w", err)
	}

	controller := &Controller{
		nc:       nc,
		js:       js,
		org:      org,
		config:   config,
		subjects: make(map[string]nats.MsgHandler),
	}

	// Setup event handlers
	controller.setupHandlers()

	return controller, nil
}

// setupHandlers configures event handlers for different GitHub events
func (c *Controller) setupHandlers() {
	// Template change handler
	c.subjects[fmt.Sprintf("github.%s.template_changed", c.org)] = c.handleTemplateChange

	// Workflow status handler
	c.subjects[fmt.Sprintf("github.%s.workflow_status", c.org)] = c.handleWorkflowStatus

	// Regeneration request handler
	c.subjects[fmt.Sprintf("github.%s.regeneration_requested", c.org)] = c.handleRegenerationRequest
}

// handleTemplateChange processes template change events
func (c *Controller) handleTemplateChange(msg *nats.Msg) {
	var event GitHubEvent
	if err := json.Unmarshal(msg.Data, &event); err != nil {
		log.Printf("Failed to unmarshal template change event: %v", err)
		return
	}

	log.Printf("🔄 Template change detected in %s", event.Repo)

	// Extract changed files
	files, ok := event.Data["files"].([]interface{})
	if !ok {
		log.Printf("No files data in event")
		return
	}

	log.Printf("   Changed files: %v", files)

	// Implement business logic:
	// 1. Validate template changes
	// 2. Check for breaking changes
	// 3. Trigger appropriate workflows
	// 4. Coordinate multi-repo updates
	// 5. Send notifications

	// For demo, we'll just trigger regeneration
	response := GitHubEvent{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Org:       c.org,
		Repo:      event.Repo,
		EventType: "regeneration_requested",
		Data: map[string]interface{}{
			"triggered_by": "controller",
			"reason":       "template_change",
			"files":        files,
		},
	}

	if err := c.publishEvent(response); err != nil {
		log.Printf("Failed to publish regeneration request: %v", err)
	}
}

// handleWorkflowStatus processes GitHub Actions workflow status updates
func (c *Controller) handleWorkflowStatus(msg *nats.Msg) {
	var event GitHubEvent
	if err := json.Unmarshal(msg.Data, &event); err != nil {
		log.Printf("Failed to unmarshal workflow status event: %v", err)
		return
	}

	workflow := event.Data["workflow"].(string)
	status := event.Data["status"].(string)

	log.Printf("📊 Workflow status: %s - %s", workflow, status)

	// Handle different workflow states
	switch status {
	case "completed":
		log.Printf("✅ Workflow completed successfully")
		// Could trigger downstream processes, notifications, etc.
	case "in_progress":
		log.Printf("🔄 Workflow in progress...")
	case "failed":
		log.Printf("❌ Workflow failed - implementing recovery...")
		// Implement retry logic, alerting, etc.
	}
}

// handleRegenerationRequest processes regeneration requests
func (c *Controller) handleRegenerationRequest(msg *nats.Msg) {
	var event GitHubEvent
	if err := json.Unmarshal(msg.Data, &event); err != nil {
		log.Printf("Failed to unmarshal regeneration request: %v", err)
		return
	}

	log.Printf("🤖 Regeneration requested for %s", event.Repo)

	// In a real implementation, this could:
	// 1. Queue the regeneration request
	// 2. Check rate limits
	// 3. Coordinate with other pending requests
	// 4. Trigger GitHub Actions via API
	// 5. Monitor progress
}

// publishEvent publishes an event to NATS
func (c *Controller) publishEvent(event GitHubEvent) error {
	data, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	subject := fmt.Sprintf("github.%s.%s", event.Org, event.EventType)
	return c.nc.Publish(subject, data)
}

// Start begins the controller event loop
func (c *Controller) Start(ctx context.Context) error {
	log.Printf("🚀 Starting GitHub workflow controller v%s", version)
	log.Printf("   Organization: %s", c.org)
	log.Printf("   NATS connection: %s", c.nc.ConnectedUrl())

	// Setup JetStream consumer for persistent event processing
	streamName := "GITHUB_EVENTS"
	consumerName := "workflow-controller"

	// Create or get consumer
	consumer, err := c.js.CreateOrUpdateConsumer(ctx, streamName, jetstream.ConsumerConfig{
		Name:          consumerName,
		Durable:       consumerName,
		FilterSubject: fmt.Sprintf("github.%s.>", c.org),
		AckPolicy:     jetstream.AckExplicitPolicy,
	})
	if err != nil {
		return fmt.Errorf("failed to create consumer: %w", err)
	}

	// Start consuming messages
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			default:
				// Fetch messages
				msgs, err := consumer.Fetch(10, jetstream.FetchMaxWait(time.Second))
				if err != nil {
					log.Printf("Failed to fetch messages: %v", err)
					time.Sleep(time.Second)
					continue
				}

				// Process each message
				for msg := range msgs.Messages() {
					c.processMessage(msg)
				}
			}
		}
	}()

	log.Printf("✅ Controller started and listening for events")

	// Wait for shutdown signal
	<-ctx.Done()
	log.Printf("🛑 Shutting down controller...")

	c.nc.Close()
	return nil
}

// processMessage processes individual NATS messages
func (c *Controller) processMessage(msg jetstream.Msg) {
	// Extract subject and route to appropriate handler
	subject := msg.Subject()

	for pattern, handler := range c.subjects {
		// Simple pattern matching - in production, use proper subject matching
		if matchSubject(pattern, subject) {
			handler(&nats.Msg{
				Subject: subject,
				Data:    msg.Data(),
			})
			msg.Ack()
			return
		}
	}

	log.Printf("No handler for subject: %s", subject)
	msg.Ack() // Acknowledge to prevent redelivery
}

// matchSubject performs simple subject pattern matching
func matchSubject(pattern, subject string) bool {
	// Simple implementation - in production, use NATS subject matching
	return subject == pattern
}

// MonitoringServer provides HTTP endpoints for health and metrics
func (c *Controller) StartMonitoringServer() {
	// In a real implementation, this would provide:
	// - Health check endpoints
	// - Prometheus metrics
	// - Controller status
	// - Event processing statistics
	log.Printf("📊 Monitoring server would start here (HTTP endpoints)")
}

// configureSynadiaAuth configures authentication for Synadia Cloud
func configureSynadiaAuth(config *NATSConfig) []nats.Option {
	var opts []nats.Option

	// Use credentials file if provided
	if config.CredsFile != "" {
		opts = append(opts, nats.UserCredentials(config.CredsFile))
	} else if config.JWT != "" && config.NKeySeed != "" {
		// Use JWT and NKey seed
		opts = append(opts, nats.UserJWTAndSeed(config.JWT, config.NKeySeed))
	} else if config.NKeyFile != "" {
		// Use NKey file
		opts = append(opts, nats.UserCredentials(config.NKeyFile))
	}

	return opts
}

// configureSelfHostedAuth configures authentication for self-hosted NATS
func configureSelfHostedAuth(config *NATSConfig) []nats.Option {
	var opts []nats.Option

	// For self-hosted, we might use basic auth, NKeys, or no auth in development
	// In production, always use proper authentication

	// Use credentials file if provided
	if config.CredsFile != "" {
		opts = append(opts, nats.UserCredentials(config.CredsFile))
	} else if config.NKeyFile != "" {
		opts = append(opts, nats.UserCredentials(config.NKeyFile))
	}
	// Note: For development/testing, we might connect without auth
	// In production, always configure proper authentication

	return opts
}

// loadNATSConfig loads NATS configuration from environment variables and files
func loadNATSConfig() (*NATSConfig, error) {
	config := &NATSConfig{
		URLs:           []string{"nats://localhost:4222"}, // Default
		MaxReconnect:   -1,                                // Infinite reconnects
		ReconnectWait:  2,                                 // 2 seconds
		Timeout:        10,                                // 10 seconds
		DeploymentType: "self_hosted",                     // Default
	}

	// Load from environment variables
	if urls := os.Getenv("NATS_URLS"); urls != "" {
		config.URLs = strings.Split(urls, ",")
	}

	if credsFile := os.Getenv("NATS_CREDS_FILE"); credsFile != "" {
		config.CredsFile = credsFile
	}

	if nkeyFile := os.Getenv("NATS_NKEY_FILE"); nkeyFile != "" {
		config.NKeyFile = nkeyFile
	}

	if jwt := os.Getenv("NATS_JWT"); jwt != "" {
		config.JWT = jwt
	}

	if nkeySeed := os.Getenv("NATS_NKEY_SEED"); nkeySeed != "" {
		config.NKeySeed = nkeySeed
	}

	if deploymentType := os.Getenv("NATS_DEPLOYMENT_TYPE"); deploymentType != "" {
		config.DeploymentType = deploymentType
	}

	if domain := os.Getenv("NATS_JETSTREAM_DOMAIN"); domain != "" {
		config.JetStreamDomain = domain
	}

	if context := os.Getenv("NATS_CONTEXT"); context != "" {
		config.Context = context
	}

	// TLS configuration
	if os.Getenv("NATS_TLS_ENABLED") == "true" {
		config.TLSEnabled = true
	}

	if os.Getenv("NATS_TLS_INSECURE") == "true" {
		config.TLSInsecure = true
	}

	if certFile := os.Getenv("NATS_TLS_CERT_FILE"); certFile != "" {
		config.TLSCertFile = certFile
	}

	if keyFile := os.Getenv("NATS_TLS_KEY_FILE"); keyFile != "" {
		config.TLSKeyFile = keyFile
	}

	if caFile := os.Getenv("NATS_TLS_CA_FILE"); caFile != "" {
		config.TLSCAFile = caFile
	}

	// Try to load from NATS context if specified
	if config.Context != "" {
		if err := loadNATSContext(config); err != nil {
			log.Printf("Warning: failed to load NATS context '%s': %v", config.Context, err)
		}
	}

	return config, nil
}

// loadNATSContext loads configuration from a NATS context (if nats CLI is available)
func loadNATSContext(config *NATSConfig) error {
	// This would integrate with the NATS CLI context system
	// For now, we'll just log that context loading was requested
	log.Printf("NATS context '%s' requested (context loading not implemented)", config.Context)
	return nil
}

// getDefaultNATSURLs returns default NATS URLs based on deployment type
func getDefaultNATSURLs(deploymentType string) []string {
	switch deploymentType {
	case "synadia_cloud":
		return []string{"connect.ngs.global"}
	case "self_hosted", "self_hosted_single":
		return []string{"nats://localhost:4222"}
	case "self_hosted_cluster":
		return []string{
			"nats://localhost:4222",
			"nats://localhost:4223",
			"nats://localhost:4224",
		}
	case "hybrid":
		return []string{
			"connect.ngs.global",
			"nats://localhost:4222",
		}
	default:
		return []string{"nats://localhost:4222"}
	}
}

func main() {
	log.Printf("🤖 NATS GitHub Controller v%s", version)

	// Load NATS configuration from environment and context
	config, err := loadNATSConfig()
	if err != nil {
		log.Fatalf("Failed to load NATS configuration: %v", err)
	}

	// Override with legacy environment variable if set
	if natsURL := os.Getenv("NATS_URL"); natsURL != "" {
		config.URLs = []string{natsURL}
	}

	// If no URLs configured, use defaults based on deployment type
	if len(config.URLs) == 0 {
		config.URLs = getDefaultNATSURLs(config.DeploymentType)
	}

	org := os.Getenv("GITHUB_ORG")
	if org == "" {
		org = "joeblew999"
	}

	log.Printf("🔧 Configuration:")
	log.Printf("   GitHub Org: %s", org)
	log.Printf("   Deployment Type: %s", config.DeploymentType)
	log.Printf("   NATS URLs: %v", config.URLs)
	log.Printf("   JetStream Domain: %s", config.JetStreamDomain)
	log.Printf("   TLS Enabled: %v", config.TLSEnabled)

	// Create controller
	controller, err := NewController(org, config)
	if err != nil {
		log.Fatalf("Failed to create controller: %v", err)
	}

	// Setup graceful shutdown
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	// Start monitoring server
	controller.StartMonitoringServer()

	// Start the controller
	if err := controller.Start(ctx); err != nil {
		log.Fatalf("Controller error: %v", err)
	}

	log.Printf("Controller shutdown complete")
}
