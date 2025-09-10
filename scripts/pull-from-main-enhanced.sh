#!/bin/bash

# Vyaapari360 ERP - Enhanced Pull from Main Script
# This script pulls latest changes from Git and syncs Supabase data/structures from main
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

# Function to backup current local state
backup_local_state() {
    log "Creating backup of current local state..."
    
    local backup_file="$BACKUP_DIR/local_backup_$TIMESTAMP.sql"
    
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

# Function to handle Git merge conflicts
handle_git_conflicts() {
    log "Checking for Git merge conflicts..."
    
    cd "$PROJECT_ROOT"
    
    # Check if there are merge conflicts
    if git diff --name-only --diff-filter=U | grep -q .; then
        log "Merge conflicts detected, resolving..."
        
        # Resolve Supabase-specific conflicts
        resolve_supabase_conflicts "$PROJECT_ROOT"
        
        # Check if there are still conflicts
        if git diff --name-only --diff-filter=U | grep -q .; then
            warning "Some conflicts remain unresolved"
            git status
            return 1
        fi
        
        success "All merge conflicts resolved"
    else
        log "No merge conflicts found"
    fi
    
    return 0
}

# Function to pull Git changes with conflict handling
pull_git_changes() {
    log "Pulling latest changes from Git..."
    
    cd "$PROJECT_ROOT"
    
    # Check if working directory is clean
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warning "Working directory has uncommitted changes"
        read -p "Do you want to stash them? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git stash push -m "Auto-stash before pull - $TIMESTAMP"
            success "Changes stashed"
        else
            error "Please commit or stash your changes before pulling"
            exit 1
        fi
    fi
    
    # Pull latest changes
    if git pull origin main --allow-unrelated-histories; then
        success "Git changes pulled successfully"
    else
        # Handle merge conflicts
        if handle_git_conflicts; then
            success "Git conflicts resolved and changes pulled"
        else
            error "Failed to resolve Git conflicts"
            exit 1
        fi
    fi
}

# Function to reset local Supabase with Docker management
reset_local_supabase() {
    log "Resetting local Supabase to match remote..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Force restart Supabase to handle any Docker issues
    if ! force_restart_supabase "$SUPABASE_PROJECT_DIR"; then
        error "Failed to restart Supabase"
        exit 1
    fi
    
    # Reset local database
    supabase db reset --linked
    
    success "Local Supabase reset completed"
}

# Function to pull Supabase migrations
pull_supabase_migrations() {
    log "Pulling Supabase migrations from remote..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Check if project is linked
    if ! is_project_linked; then
        log "Linking Supabase project..."
        supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"
    fi
    
    # Pull migrations from remote
    log "Pulling database migrations..."
    supabase db pull --password "$SUPABASE_DB_PASSWORD"
    
    success "Supabase migrations pulled successfully"
}

# Function to pull Supabase data
pull_supabase_data() {
    log "Pulling Supabase data from remote..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Get remote database URL
    local remote_db_url=$(get_remote_db_url)
    
    if [ -z "$remote_db_url" ]; then
        warning "Could not get remote database URL, skipping data pull"
        return 0
    fi
    
    # Export data from remote
    local data_file="$BACKUP_DIR/remote_data_$TIMESTAMP.sql"
    log "Exporting data from remote Supabase..."
    export_data_only "$remote_db_url" "$data_file" || {
        warning "Could not export remote data, continuing..."
        return 0
    }
    
    # Get local database URL
    local local_db_url=$(get_local_db_url)
    
    if [ -n "$local_db_url" ] && [ -f "$data_file" ]; then
        log "Importing data to local Supabase..."
        import_data_only "$local_db_url" "$data_file" || {
            warning "Could not import data to local, continuing..."
        }
    fi
    
    success "Supabase data pulled successfully"
}

# Function to start local Supabase with health check
start_local_supabase() {
    log "Starting local Supabase..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Start Supabase
    if supabase start; then
        success "Local Supabase started"
        
        # Wait a moment for services to be ready
        sleep 5
        
        # Check health
        if check_supabase_health "$SUPABASE_PROJECT_DIR"; then
            success "Supabase is healthy and ready"
        else
            warning "Supabase started but health check failed"
        fi
    else
        error "Failed to start local Supabase"
        exit 1
    fi
}

# Function to verify sync
verify_sync() {
    log "Verifying sync status..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Show migration status
    log "Migration status:"
    check_migration_status
    
    # Show project status
    log "Project status:"
    show_project_status
    
    # Check health
    if check_supabase_health "$SUPABASE_PROJECT_DIR"; then
        success "Sync verification completed - all systems healthy"
    else
        warning "Sync verification completed with warnings"
    fi
}

# Function to restore stashed changes
restore_stashed_changes() {
    log "Checking for stashed changes..."
    
    cd "$PROJECT_ROOT"
    
    if git stash list | grep -q "Auto-stash before pull"; then
        read -p "Do you want to restore your stashed changes? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git stash pop
            success "Stashed changes restored"
        else
            log "Stashed changes kept in stash"
        fi
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
    
    error "Pull operation failed - cleanup completed"
}

# Main execution
main() {
    log "Starting Vyaapari360 ERP enhanced pull from main process..."
    
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
    backup_local_state
    pull_git_changes
    reset_local_supabase
    pull_supabase_migrations
    pull_supabase_data
    start_local_supabase
    verify_sync
    restore_stashed_changes
    
    success "Enhanced pull from main completed successfully!"
    log "Summary:"
    log "- Git changes pulled from main branch"
    log "- Merge conflicts resolved automatically"
    log "- Local Supabase reset and synced with Docker management"
    log "- Remote Supabase migrations pulled"
    log "- Remote Supabase data imported"
    log "- Local Supabase started with health verification"
    log "- Backup created in: $BACKUP_DIR"
}

# Run main function
main "$@"
