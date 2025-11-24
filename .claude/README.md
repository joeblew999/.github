# Claude Agent Configuration

This directory contains specialized agent configurations for Claude Code to provide context-specific expertise when working in this repository.

## Agents

### [github-meta-repo-expert.md](agents/github-meta-repo-expert.md)
Expert agent for GitHub meta-repository management, template systems, and organization-wide automation.

**Use when:**
- Working with template system
- Managing organization-wide configurations
- Dealing with the "snake eating its tail" problem
- Cross-platform tooling questions
- NATS orchestration setup
- Documentation organization

**Key knowledge areas:**
- Template-based automation patterns
- Idempotent operations
- GitHub Actions workflows
- Taskfile task runner
- NATS event-driven architecture
- Cross-platform Go CLI tooling

## Usage

Claude Code automatically loads these agent configurations when working in this repository, providing specialized knowledge and best practices specific to meta-repository management.
