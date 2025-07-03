package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

const version = "1.0.0"

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
	subjects map[string]nats.MsgHandler
}

// NewController creates a new workflow controller
func NewController(natsURL, org string) (*Controller, error) {
	nc, err := nats.Connect(natsURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to NATS: %w", err)
	}

	js, err := jetstream.New(nc)
	if err != nil {
		return nil, fmt.Errorf("failed to create JetStream context: %w", err)
	}

	controller := &Controller{
		nc:       nc,
		js:       js,
		org:      org,
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
		Name:        consumerName,
		Durable:     consumerName,
		FilterSubject: fmt.Sprintf("github.%s.>", c.org),
		AckPolicy:   jetstream.AckExplicitPolicy,
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

func main() {
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = "nats://localhost:4222"
	}

	org := os.Getenv("GITHUB_ORG")
	if org == "" {
		org = "joeblew999"
	}

	// Create controller
	controller, err := NewController(natsURL, org)
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
