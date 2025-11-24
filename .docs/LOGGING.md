# Logging

We use Go's standard `log/slog` with the [samber slog ecosystem](https://github.com/samber) for structured logging.

## Why samber?

- **25+ handlers** for different outputs (NATS, Slack, files, etc.)
- **Converters** for existing loggers (logrus, zap, zerolog)
- **HTTP middleware** for all frameworks (gin, echo, fiber, chi)
- **Advanced features** (multi-handler, sampling, formatting)

## Usage

```go
import "log/slog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
logger.Info("message", "key", "value")
```

## Extensions

Add any samber handler when needed:

```bash
go get github.com/samber/slog-nats    # NATS integration
go get github.com/samber/slog-multi   # Multi-handler support
go get github.com/samber/slog-gin     # Gin middleware
```

## Resources

- [samber slog ecosystem](https://github.com/samber?tab=repositories&q=slog)
- [Go slog documentation](https://pkg.go.dev/log/slog)
