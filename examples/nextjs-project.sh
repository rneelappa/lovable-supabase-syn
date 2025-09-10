#!/bin/bash

# Example configuration for a Next.js project with Supabase
# Copy this to your project's .supabase-sync/config/project-config.sh

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

# Project Information
PROJECT_NAME="My Next.js App"
PROJECT_DESCRIPTION="A Next.js application with Supabase backend"

# Git Configuration
GIT_REMOTE_URL="https://github.com/your-username/my-nextjs-app.git"
GIT_BRANCH="main"
GIT_WORKING_DIR="."

# Supabase Configuration
SUPABASE_PROJECT_REF="your-supabase-project-ref"
SUPABASE_DB_PASSWORD="your-supabase-password"
SUPABASE_PROJECT_DIR="supabase"  # Supabase project in root directory

# Backup Configuration
BACKUP_DIR="./backups/supabase"
BACKUP_RETENTION_DAYS=30

# Docker Configuration
DOCKER_AUTO_START=true
DOCKER_CLEANUP_ON_FAILURE=true

# Port Configuration
SUPABASE_API_PORT=54321
SUPABASE_DB_PORT=54322
SUPABASE_STUDIO_PORT=54323
SUPABASE_INBUCKET_PORT=54324

# Health Check Configuration
HEALTH_CHECK_TIMEOUT=30
HEALTH_CHECK_RETRIES=3

# Logging Configuration
LOG_LEVEL="INFO"
LOG_FILE="./logs/supabase-sync.log"

# =============================================================================
# ADVANCED CONFIGURATION
# =============================================================================

# Conflict Resolution Strategy
CONFLICT_RESOLUTION_STRATEGY="smart"

# File-specific conflict resolution for Next.js projects
declare -A CONFLICT_RESOLUTION=(
    ["supabase/config.toml"]="local"
    [".env"]="local"
    [".env.local"]="local"
    [".env.production"]="local"
    [".env.development"]="local"
    ["supabase/migrations/*"]="remote"
    ["package.json"]="local"
    ["package-lock.json"]="local"
    ["yarn.lock"]="local"
    ["next.config.js"]="local"
    ["next.config.ts"]="local"
    ["tailwind.config.js"]="local"
    ["tailwind.config.ts"]="local"
    ["tsconfig.json"]="local"
    ["app/**/*.ts"]="local"
    ["app/**/*.tsx"]="local"
    ["app/**/*.js"]="local"
    ["app/**/*.jsx"]="local"
    ["pages/**/*.ts"]="local"
    ["pages/**/*.tsx"]="local"
    ["pages/**/*.js"]="local"
    ["pages/**/*.jsx"]="local"
    ["components/**/*.ts"]="local"
    ["components/**/*.tsx"]="local"
    ["lib/**/*.ts"]="local"
    ["lib/**/*.js"]="local"
    ["public/**/*"]="local"
    ["*.md"]="local"
    ["README.md"]="local"
)

# Backup Strategy
BACKUP_STRATEGY="full"

# Migration Strategy
MIGRATION_STRATEGY="safe"

# Data Sync Strategy
DATA_SYNC_STRATEGY="bidirectional"

# Export configuration variables
export PROJECT_NAME PROJECT_DESCRIPTION
export GIT_REMOTE_URL GIT_BRANCH GIT_WORKING_DIR
export SUPABASE_PROJECT_REF SUPABASE_DB_PASSWORD SUPABASE_PROJECT_DIR
export BACKUP_DIR BACKUP_RETENTION_DAYS
export DOCKER_AUTO_START DOCKER_CLEANUP_ON_FAILURE
export SUPABASE_API_PORT SUPABASE_DB_PORT SUPABASE_STUDIO_PORT SUPABASE_INBUCKET_PORT
export HEALTH_CHECK_TIMEOUT HEALTH_CHECK_RETRIES
export LOG_LEVEL LOG_FILE
export CONFLICT_RESOLUTION_STRATEGY CONFLICT_RESOLUTION
export BACKUP_STRATEGY MIGRATION_STRATEGY DATA_SYNC_STRATEGY
