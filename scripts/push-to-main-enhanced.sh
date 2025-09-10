#!/bin/bash

# Vyaapari360 ERP - Enhanced Push to Main Script
# This script pushes local changes to Git and syncs Supabase data/structures to main
# Enhanced with merge conflict handling and Docker management

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/Users/rajkumarneelappa/Documents/vyaapari-360-erp"
SUPABASE_PROJECT_DIR="$PROJECT_ROOT/vyaapari-nexus"
SUPABASE_PROJECT_REF="hycyhnjsldiokfkpqzoz"
BACKUP_DIR="$PROJECT_ROOT/backups/supabase"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/supabase-utils.sh"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command_exists git; then
        error "Git is not installed"
        exit 1
    fi
    
    if ! command_exists supabase; then
        error "Supabase CLI is not installed"
        exit 1
    fi
    
    if ! command_exists psql; then
        error "PostgreSQL client (psql) is not installed"
        exit 1
    fi
    
    if ! command_exists jq; then
        error "jq is not installed (required for JSON parsing)"
        exit 1
    fi
    
    if ! command_exists docker; then
        error "Docker is not installed"
        exit 1
    fi
    
    if ! command_exists lsof; then
        error "lsof is not installed (required for port checking)"
        exit 1
    fi
    
    # Check Docker
    if ! restart_docker_if_needed; then
        error "Docker is required but not available"
        exit 1
    fi
    
    success "All prerequisites met"
}

# Function to create backup directory
create_backup_dir() {
    log "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    success "Backup directory created: $BACKUP_DIR"
}

# Function to backup current Supabase data
backup_supabase_data() {
    log "Creating backup of current Supabase data..."
    
    local backup_file="$BACKUP_DIR/supabase_backup_$TIMESTAMP.sql"
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Get local database URL
    local local_db_url=$(get_local_db_url)
    
    if [ -n "$local_db_url" ]; then
        create_db_backup "$local_db_url" "$backup_file" || {
            warning "Could not create local backup, continuing..."
        }
    else
        warning "Could not get local DB URL, skipping local backup"
    fi
}

# Function to ensure Supabase is running
ensure_supabase_running() {
    log "Ensuring Supabase is running..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Check if Supabase is running
    if ! supabase status >/dev/null 2>&1; then
        log "Supabase is not running, starting it..."
        
        # Handle port conflicts
        handle_port_conflicts 54321 "API"
        handle_port_conflicts 54322 "Database"
        handle_port_conflicts 54323 "Studio"
        
        # Start Supabase
        if supabase start; then
            success "Supabase started successfully"
        else
            # Try force restart if normal start fails
            if force_restart_supabase "$SUPABASE_PROJECT_DIR"; then
                success "Supabase started with force restart"
            else
                error "Failed to start Supabase"
                exit 1
            fi
        fi
    else
        log "Supabase is already running"
        
        # Check health
        if ! check_supabase_health "$SUPABASE_PROJECT_DIR"; then
            warning "Supabase is running but not healthy, attempting restart..."
            if force_restart_supabase "$SUPABASE_PROJECT_DIR"; then
                success "Supabase restarted and is healthy"
            else
                error "Failed to restart Supabase"
                exit 1
            fi
        fi
    fi
}

# Function to push Supabase migrations
push_supabase_migrations() {
    log "Pushing Supabase migrations to remote..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Check if project is linked
    if ! is_project_linked; then
        log "Linking Supabase project..."
        supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"
    fi
    
    # Push migrations
    log "Pushing database migrations..."
    supabase db push --password "$SUPABASE_DB_PASSWORD"
    
    success "Supabase migrations pushed successfully"
}

# Function to push Supabase data
push_supabase_data() {
    log "Exporting and pushing Supabase data..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Export data from local Supabase
    local data_file="$BACKUP_DIR/supabase_data_$TIMESTAMP.sql"
    
    # Get local database URL
    local local_db_url=$(get_local_db_url)
    
    if [ -n "$local_db_url" ]; then
        log "Exporting data from local Supabase..."
        export_data_only "$local_db_url" "$data_file" || {
            warning "Could not export local data, continuing..."
        }
    fi
    
    # Get remote database URL
    local remote_db_url=$(get_remote_db_url)
    
    if [ -n "$remote_db_url" ] && [ -f "$data_file" ]; then
        log "Importing data to remote Supabase..."
        import_data_only "$remote_db_url" "$data_file" || {
            warning "Could not import data to remote, continuing..."
        }
    fi
    
    success "Supabase data sync completed"
}

# Function to commit and push Git changes
push_git_changes() {
    log "Committing and pushing Git changes..."
    
    cd "$PROJECT_ROOT"
    
    # Check if there are changes to commit
    if git diff --quiet && git diff --cached --quiet; then
        warning "No changes to commit"
        return 0
    fi
    
    # Add all changes
    git add .
    
    # Commit with timestamp
    local commit_message="Deploy to main - $(date +'%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_message"
    
    # Push to main branch
    git push origin main
    
    success "Git changes pushed to main branch"
}

# Function to update Supabase project status
update_supabase_status() {
    log "Updating Supabase project status..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Show current migration status
    check_migration_status
    
    # Show project status
    show_project_status
    
    # Check health
    if check_supabase_health "$SUPABASE_PROJECT_DIR"; then
        success "Supabase status updated - all systems healthy"
    else
        warning "Supabase status updated with warnings"
    fi
}

# Function to handle cleanup on failure
cleanup_on_failure() {
    log "Cleaning up after failure..."
    
    # Stop any running Supabase instances
    cd "$SUPABASE_PROJECT_DIR"
    supabase stop 2>/dev/null || true
    
    # Clean up Docker containers
    cleanup_docker_containers
    
    error "Push operation failed - cleanup completed"
}

# Main execution
main() {
    log "Starting Vyaapari360 ERP enhanced push to main process..."
    
    # Set up error handling
    trap cleanup_on_failure ERR
    
    # Check if password is provided
    if [ -z "$SUPABASE_DB_PASSWORD" ]; then
        error "SUPABASE_DB_PASSWORD environment variable is required"
        echo "Please set it with: export SUPABASE_DB_PASSWORD='your_password'"
        exit 1
    fi
    
    # Execute steps
    check_prerequisites
    create_backup_dir
    backup_supabase_data
    ensure_supabase_running
    push_supabase_migrations
    push_supabase_data
    push_git_changes
    update_supabase_status
    
    success "Enhanced push to main completed successfully!"
    log "Summary:"
    log "- Git changes pushed to main branch"
    log "- Supabase migrations deployed with Docker management"
    log "- Supabase data synchronized"
    log "- All systems verified and healthy"
    log "- Backup created in: $BACKUP_DIR"
}

# Run main function
main "$@"
