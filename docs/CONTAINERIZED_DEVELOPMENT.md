# Containerized Development and Ruby Version Management

## Overview

This document explains why the `.ruby-version` file is not needed in containerized development environments and how it relates to our development workflow.

## Traditional Ruby Version Management

### What is `.ruby-version`?

The `.ruby-version` file is a simple text file that specifies which Ruby version should be used for a project. It's primarily used by Ruby version managers like:

- **rbenv** - Manages multiple Ruby versions on a single machine
- **rvm** - Ruby Version Manager
- **chruby** - Changes the current Ruby version
- **asdf** - Universal version manager

### How it works in traditional development

When you navigate into a project directory:
1. Your version manager reads the `.ruby-version` file
2. It automatically switches to the specified Ruby version
3. If that version isn't installed, it prompts you to install it

**Example scenario:**
```bash
$ cd my-project
$ cat .ruby-version
2.7.1
$ ruby --version
ruby 2.7.1p83 (2021-07-07 revision ...) [x86_64-linux]
```

## Containerized Development

### What is containerized development?

With containerized development using Docker:
1. The **Dockerfile** explicitly specifies the Ruby version in the base image
2. Developers work inside a container with a pre-configured environment
3. Everyone uses the **exact same** Ruby version, libraries, and dependencies

### Our Setup

Looking at our `Dockerfile`:
```dockerfile
FROM ruby:3.3-slim-bookworm
```

This line **explicitly** declares we're using Ruby 3.3. The container provides:
- ✅ Consistent Ruby version across all developers
- ✅ Consistent system dependencies (libglib, libcairo, etc.)
- ✅ Isolated environment (no conflicts with host system)
- ✅ Reproducible builds

### Why `.ruby-version` becomes redundant

When using containerized development:

1. **The Dockerfile is the source of truth** - Ruby version is specified there
2. **rbenv doesn't run inside containers** - Version managers are typically not installed in Docker images
3. **Version conflicts arise** - If `.ruby-version` says `2.7.1` but Dockerfile uses `ruby:3.3`, rbenv will complain on the host machine
4. **No benefit on host** - Developers don't run Ruby directly on their host machines; they use `make` or `docker-compose`

## The Problem That Was Solved

### Before removing `.ruby-version`:

```
.ruby-version contains: 2.7.1
Dockerfile contains: ruby:3.3-slim-bookworm
```

**What happened:**
- Developer has rbenv installed on their host machine
- They navigate to the project directory
- rbenv sees `.ruby-version` specifying 2.7.1
- rbenv complains: "Ruby version 2.7.1 is not installed"
- Developer gets confused because they're supposed to use Docker anyway
- The file serves no purpose since all development happens in containers

### After removing `.ruby-version`:

```
Dockerfile contains: ruby:3.3-slim-bookworm (source of truth)
morandi.gemspec contains: required_ruby_version = '>= 2.7' (runtime requirement)
```

**Benefits:**
- ✅ No rbenv conflicts or complaints
- ✅ Single source of truth for development (Dockerfile)
- ✅ Runtime requirements still enforced via gemspec
- ✅ Cleaner, less confusing project structure

## Version Requirements in Different Contexts

Our project maintains Ruby version requirements in appropriate places:

### 1. **Development Environment** (Dockerfile)
```dockerfile
FROM ruby:3.3-slim-bookworm
```
→ Specifies exact version for development consistency

### 2. **Runtime Requirements** (gemspec)
```ruby
spec.required_ruby_version = '>= 2.7'
```
→ Specifies minimum version for gem users

### 3. **CI/CD** (GitHub Actions or similar)
Would specify Ruby version in workflow files:
```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.3'
```

## Development Workflow

### For contributors:

```bash
# Start development environment
make

# Or manually with docker
docker build -t morandi .
docker run -v $(pwd):/app morandi

# Get a shell inside the container
make shell
```

The Ruby version is automatically correct inside the container - no manual version management needed!

## When You WOULD Still Need `.ruby-version`

You would keep `.ruby-version` if:

- ❌ Developers run Ruby directly on their host machines (not containerized)
- ❌ Using rbenv/rvm/chruby for local development
- ❌ No Dockerfile or container-based workflow exists

Since we **do** use containerized development (see README.md "Development" section), we don't need it.

## Conclusion

The removal of `.ruby-version` is a **quality-of-life improvement** that:
- Eliminates confusion and version manager complaints
- Aligns with our containerized development workflow
- Maintains proper version requirements where they matter (gemspec for runtime, Dockerfile for development)
- Simplifies the development setup for new contributors

For version requirements, contributors should:
- **Development**: Trust the Dockerfile (automatic when using `make`)
- **Runtime**: Trust the gemspec (enforced by RubyGems)
- **CI/CD**: Trust the workflow configuration
