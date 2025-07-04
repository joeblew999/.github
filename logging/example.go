package main

import (
	"context"
	"log/slog"
	"os"
	"time"

	"github.com/nats-io/nats.go"
	slognats "github.com/samber/slog-nats"
)

func main() {
	// Setup multiple handlers
	var handlers []slog.Handler

	// Determine log level from environment
	logLevel := slog.LevelInfo
	if os.Getenv("LOG_LEVEL") == "debug" {
		logLevel = slog.LevelDebug
	}

	// Local console handler (text or JSON based on environment)
	var consoleHandler slog.Handler
	if os.Getenv("LOG_FORMAT") == "json" {
		consoleHandler = slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
			Level: logLevel,
		})
	} else {
		consoleHandler = slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
			Level: logLevel,
		})
	}
	handlers = append(handlers, consoleHandler)

	// NATS handler (if NATS URL is provided)
	natsURL := os.Getenv("NATS_URL")
	if natsURL != "" {
		// Setup NATS connection options
		opts := []nats.Option{}

		// Add credentials if provided
		if credsFile := os.Getenv("NATS_CREDS"); credsFile != "" {
			opts = append(opts, nats.UserCredentials(credsFile))
		}

		// Add token if provided
		if token := os.Getenv("NATS_TOKEN"); token != "" {
			opts = append(opts, nats.Token(token))
		}

		// Connect to NATS
		nc, err := nats.Connect(natsURL, opts...)
		if err != nil {
			slog.New(consoleHandler).Error("failed to connect to NATS", "error", err, "url", natsURL)
		} else {
			defer nc.Close()

			// Create encoded connection for JSON messages
			ec, err := nats.NewEncodedConn(nc, nats.JSON_ENCODER)
			if err != nil {
				slog.New(consoleHandler).Error("failed to create encoded NATS connection", "error", err)
			} else {
				defer ec.Close()

				// Create NATS handler (use same log level as console)
				natsHandler := slognats.Option{
					Level:             logLevel,
					EncodedConnection: ec,
					Subject:           "logs.registry", // NATS subject for logs
				}.NewNATSHandler()

				handlers = append(handlers, natsHandler)
				slog.New(consoleHandler).Info("NATS logging enabled", "url", natsURL, "subject", "logs.registry")
			}
		}
	}

	// Create multi-handler logger
	var logger *slog.Logger
	if len(handlers) == 1 {
		logger = slog.New(handlers[0])
	} else {
		// Use a multi-handler approach (simple implementation)
		logger = slog.New(&multiHandler{handlers: handlers})
	}

	// Example structured logging
	logger.Info("application starting", "handlers", len(handlers))

	// Simulate registry validation
	start := time.Now()
	logger.Info("validating registry", "operation", "validate")

	// Simulate work
	time.Sleep(100 * time.Millisecond)

	// Log with structured data
	endpointCount := 42
	logger.Info("validation completed",
		"endpoint_count", endpointCount,
		"duration", time.Since(start),
		"status", "success")

	// Error example
	if endpointCount < 50 {
		logger.Warn("low endpoint count",
			"count", endpointCount,
			"threshold", 50)
	}

	// Debug level (won't show unless level is debug)
	logger.Debug("debug information", "internal_state", "ok")

	logger.Info("application completed")
}

// Simple multi-handler implementation
type multiHandler struct {
	handlers []slog.Handler
}

func (m *multiHandler) Enabled(ctx context.Context, level slog.Level) bool {
	for _, h := range m.handlers {
		if h.Enabled(ctx, level) {
			return true
		}
	}
	return false
}

func (m *multiHandler) Handle(ctx context.Context, record slog.Record) error {
	for _, h := range m.handlers {
		if h.Enabled(ctx, record.Level) {
			if err := h.Handle(ctx, record); err != nil {
				return err
			}
		}
	}
	return nil
}

func (m *multiHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	var newHandlers []slog.Handler
	for _, h := range m.handlers {
		newHandlers = append(newHandlers, h.WithAttrs(attrs))
	}
	return &multiHandler{handlers: newHandlers}
}

func (m *multiHandler) WithGroup(name string) slog.Handler {
	var newHandlers []slog.Handler
	for _, h := range m.handlers {
		newHandlers = append(newHandlers, h.WithGroup(name))
	}
	return &multiHandler{handlers: newHandlers}
}
