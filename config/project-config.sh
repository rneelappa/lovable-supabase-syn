#!/bin/bash

# Lovable Supabase Sync - Project Configuration
# This file contains the configuration for your specific project
# Copy this file and customize it for your project

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

# Project Information
PROJECT_NAME="Your Project Name"
PROJECT_DESCRIPTION="Your project description"

# Git Configuration
GIT_REMOTE_URL="https://github.com/your-username/your-repo.git"
GIT_BRANCH="main"
GIT_WORKING_DIR="."

# Supabase Configuration
SUPABASE_PROJECT_REF="your-supabase-project-ref"
SUPABASE_DB_PASSWORD="your-supabase-password"
SUPABASE_PROJECT_DIR="supabase"  # Relative to working directory

# Backup Configuration
BACKUP_DIR="./backups/supabase"
BACKUP_RETENTION_DAYS=30

# Docker Configuration
DOCKER_AUTO_START=true
DOCKER_CLEANUP_ON_FAILURE=true

# Port Configuration (Supabase default ports)
SUPABASE_API_PORT=54321
SUPABASE_DB_PORT=54322
SUPABASE_STUDIO_PORT=54323
SUPABASE_INBUCKET_PORT=54324

# Health Check Configuration
HEALTH_CHECK_TIMEOUT=30
HEALTH_CHECK_RETRIES=3

# Logging Configuration
LOG_LEVEL="INFO"  # DEBUG, INFO, WARNING, ERROR
LOG_FILE="./logs/supabase-sync.log"

# =============================================================================
# ADVANCED CONFIGURATION
# =============================================================================

# Conflict Resolution Strategy
CONFLICT_RESOLUTION_STRATEGY="smart"  # smart, local, remote, manual

# File-specific conflict resolution
declare -A CONFLICT_RESOLUTION=(
    ["supabase/config.toml"]="local"
    [".env"]="local"
    ["supabase/migrations/*"]="remote"
    ["package.json"]="local"
    ["package-lock.json"]="local"
    ["yarn.lock"]="local"
    ["*.md"]="local"
)

# Backup Strategy
BACKUP_STRATEGY="full"  # full, incremental, schema-only, data-only

# Migration Strategy
MIGRATION_STRATEGY="safe"  # safe, force, interactive

# Data Sync Strategy
DATA_SYNC_STRATEGY="bidirectional"  # bidirectional, local-to-remote, remote-to-local, none

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Function to validate configuration
validate_config() {
    local errors=0
    
    # Check required variables
    if [ -z "$GIT_REMOTE_URL" ] || [ "$GIT_REMOTE_URL" = "https://github.com/your-username/your-repo.git" ]; then
        echo "ERROR: GIT_REMOTE_URL must be set to your actual Git repository URL"
        errors=$((errors + 1))
    fi
    
    if [ -z "$SUPABASE_PROJECT_REF" ] || [ "$SUPABASE_PROJECT_REF" = "your-supabase-project-ref" ]; then
        echo "ERROR: SUPABASE_PROJECT_REF must be set to your actual Supabase project reference"
        errors=$((errors + 1))
    fi
    
    if [ -z "$SUPABASE_DB_PASSWORD" ] || [ "$SUPABASE_DB_PASSWORD" = "your-supabase-password" ]; then
        echo "ERROR: SUPABASE_DB_PASSWORD must be set to your actual Supabase password"
        errors=$((errors + 1))
    fi
    
    # Check if working directory exists
    if [ ! -d "$GIT_WORKING_DIR" ]; then
        echo "ERROR: GIT_WORKING_DIR '$GIT_WORKING_DIR' does not exist"
        errors=$((errors + 1))
    fi
    
    # Check if Supabase project directory exists
    if [ ! -d "$GIT_WORKING_DIR/$SUPABASE_PROJECT_DIR" ]; then
        echo "ERROR: SUPABASE_PROJECT_DIR '$GIT_WORKING_DIR/$SUPABASE_PROJECT_DIR' does not exist"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        echo "Configuration validation failed with $errors errors"
        return 1
    fi
    
    echo "Configuration validation passed"
    return 0
}

# Function to show current configuration
show_config() {
    echo "=== Project Configuration ==="
    echo "Project Name: $PROJECT_NAME"
    echo "Git Remote: $GIT_REMOTE_URL"
    echo "Git Branch: $GIT_BRANCH"
    echo "Working Directory: $GIT_WORKING_DIR"
    echo "Supabase Project Ref: $SUPABASE_PROJECT_REF"
    echo "Supabase Project Dir: $SUPABASE_PROJECT_DIR"
    echo "Backup Directory: $BACKUP_DIR"
    echo "Conflict Resolution: $CONFLICT_RESOLUTION_STRATEGY"
    echo "Backup Strategy: $BACKUP_STRATEGY"
    echo "Migration Strategy: $MIGRATION_STRATEGY"
    echo "Data Sync Strategy: $DATA_SYNC_STRATEGY"
    echo "============================="
}

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
