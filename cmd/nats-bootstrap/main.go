package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/nats-io/nats-server/v2/server"
	"github.com/nats-io/nats.go"
)

const version = "1.0.0"

// EmbeddedNATS provides a simple embedded NATS server for bootstrap/development
type EmbeddedNATS struct {
	server  *server.Server
	opts    *server.Options
	tempDir string
}

// NewEmbeddedNATS creates a new embedded NATS server
func NewEmbeddedNATS() (*EmbeddedNATS, error) {
	// Create temporary directory for JetStream storage
	tempDir, err := os.MkdirTemp("", "nats-bootstrap-*")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp directory: %w", err)
	}

	opts := &server.Options{
		Host:     "127.0.0.1",
		Port:     4222,
		HTTPHost: "127.0.0.1",
		HTTPPort: 8222,

		// JetStream configuration
		JetStream: true,
		StoreDir:  filepath.Join(tempDir, "jetstream"),

		// Logging
		Debug:   false,
		Trace:   false,
		Logtime: true,
		NoLog:   false,

		// Cluster name for development
		ServerName: "nats-bootstrap",
	}

	s, err := server.NewServer(opts)
	if err != nil {
		return nil, fmt.Errorf("failed to create NATS server: %w", err)
	}

	return &EmbeddedNATS{
		server:  s,
		opts:    opts,
		tempDir: tempDir,
	}, nil
}

// Start starts the embedded NATS server
func (e *EmbeddedNATS) Start() error {
	log.Printf("🚀 Starting embedded NATS server v%s", version)
	log.Printf("   Server: %s:%d", e.opts.Host, e.opts.Port)
	log.Printf("   HTTP Monitor: %s:%d", e.opts.HTTPHost, e.opts.HTTPPort)
	log.Printf("   JetStream Store: %s", e.opts.StoreDir)

	// Start the server
	go e.server.Start()

	// Wait for server to be ready
	if !e.server.ReadyForConnections(10 * time.Second) {
		return fmt.Errorf("NATS server failed to start within 10 seconds")
	}

	log.Printf("✅ NATS server started successfully")

	// Test basic connectivity
	if err := e.testConnectivity(); err != nil {
		log.Printf("⚠️ Warning: connectivity test failed: %v", err)
	} else {
		log.Printf("✅ Connectivity test passed")
	}

	// Create basic JetStream configuration for GitHub events
	if err := e.setupGitHubStreams(); err != nil {
		log.Printf("⚠️ Warning: failed to setup GitHub streams: %v", err)
	} else {
		log.Printf("✅ GitHub event streams configured")
	}

	return nil
}

// Stop stops the embedded NATS server
func (e *EmbeddedNATS) Stop() {
	log.Printf("🛑 Stopping embedded NATS server...")

	if e.server != nil {
		e.server.Shutdown()
		e.server.WaitForShutdown()
	}

	// Cleanup temporary directory
	if e.tempDir != "" {
		if err := os.RemoveAll(e.tempDir); err != nil {
			log.Printf("Warning: failed to cleanup temp directory: %v", err)
		} else {
			log.Printf("✅ Temporary files cleaned up")
		}
	}

	log.Printf("✅ NATS server stopped")
}

// testConnectivity tests basic NATS connectivity
func (e *EmbeddedNATS) testConnectivity() error {
	nc, err := nats.Connect(fmt.Sprintf("nats://%s:%d", e.opts.Host, e.opts.Port))
	if err != nil {
		return fmt.Errorf("failed to connect: %w", err)
	}
	defer nc.Close()

	// Test basic pub/sub
	if err := nc.Publish("test.bootstrap", []byte("Bootstrap test message")); err != nil {
		return fmt.Errorf("failed to publish: %w", err)
	}

	return nil
}

// setupGitHubStreams creates JetStream streams for GitHub events
func (e *EmbeddedNATS) setupGitHubStreams() error {
	nc, err := nats.Connect(fmt.Sprintf("nats://%s:%d", e.opts.Host, e.opts.Port))
	if err != nil {
		return fmt.Errorf("failed to connect: %w", err)
	}
	defer nc.Close()

	js, err := nc.JetStream()
	if err != nil {
		return fmt.Errorf("failed to get JetStream context: %w", err)
	}

	// Create GitHub events stream
	streamConfig := &nats.StreamConfig{
		Name:        "GITHUB_EVENTS",
		Description: "GitHub organization events for workflow automation",
		Subjects:    []string{"github.>"},
		Storage:     nats.FileStorage,
		MaxAge:      24 * time.Hour,    // Keep events for 24 hours
		MaxMsgs:     10000,             // Keep last 10k messages
		MaxBytes:    100 * 1024 * 1024, // 100MB max
		Replicas:    1,                 // Single replica for development
	}

	_, err = js.AddStream(streamConfig)
	if err != nil && err != nats.ErrStreamNameAlreadyInUse {
		return fmt.Errorf("failed to create GitHub events stream: %w", err)
	}

	// Create workflow coordination stream
	workflowConfig := &nats.StreamConfig{
		Name:        "WORKFLOW_COORDINATION",
		Description: "Workflow coordination and locking",
		Subjects:    []string{"workflow.>", "locks.>"},
		Storage:     nats.FileStorage,
		MaxAge:      1 * time.Hour,    // Keep locks for 1 hour max
		MaxMsgs:     1000,             // Keep last 1k messages
		MaxBytes:    10 * 1024 * 1024, // 10MB max
		Replicas:    1,
	}

	_, err = js.AddStream(workflowConfig)
	if err != nil && err != nats.ErrStreamNameAlreadyInUse {
		return fmt.Errorf("failed to create workflow coordination stream: %w", err)
	}

	return nil
}

// GetConnectionURL returns the NATS connection URL
func (e *EmbeddedNATS) GetConnectionURL() string {
	return fmt.Sprintf("nats://%s:%d", e.opts.Host, e.opts.Port)
}

// GetMonitorURL returns the HTTP monitor URL
func (e *EmbeddedNATS) GetMonitorURL() string {
	return fmt.Sprintf("http://%s:%d", e.opts.HTTPHost, e.opts.HTTPPort)
}

func main() {
	log.Printf("🤖 NATS Bootstrap Server v%s", version)

	// Create embedded NATS
	natsServer, err := NewEmbeddedNATS()
	if err != nil {
		log.Fatalf("Failed to create NATS server: %v", err)
	}

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Start server
	if err := natsServer.Start(); err != nil {
		log.Fatalf("Failed to start NATS server: %v", err)
	}

	log.Printf("🎯 Bootstrap NATS ready for GitHub automation!")
	log.Printf("   Connection URL: %s", natsServer.GetConnectionURL())
	log.Printf("   Monitor URL: %s", natsServer.GetMonitorURL())
	log.Printf("   Press Ctrl+C to stop")

	// Wait for shutdown signal
	<-sigChan

	// Graceful shutdown
	natsServer.Stop()
	log.Printf("👋 Bootstrap complete!")
}
