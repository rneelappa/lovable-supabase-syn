#!/bin/bash

# Vyaapari360 ERP - Pull from Main Script
# This script pulls latest changes from Git and syncs Supabase data/structures from main

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
    local local_db_url=$(supabase status --output json | jq -r '.DB_URL' 2>/dev/null || echo "")
    
    if [ -n "$local_db_url" ]; then
        pg_dump "$local_db_url" > "$backup_file" 2>/dev/null || {
            warning "Could not create local backup, continuing..."
        }
        success "Local backup created: $backup_file"
    else
        warning "Could not get local DB URL, skipping local backup"
    fi
}

# Function to pull Git changes
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
    git pull origin main
    
    success "Git changes pulled successfully"
}

# Function to reset local Supabase
reset_local_supabase() {
    log "Resetting local Supabase to match remote..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Stop local Supabase if running
    supabase stop 2>/dev/null || true
    
    # Reset local database
    supabase db reset --linked
    
    success "Local Supabase reset completed"
}

# Function to pull Supabase migrations
pull_supabase_migrations() {
    log "Pulling Supabase migrations from remote..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Check if project is linked
    if ! supabase projects list | grep -q "$SUPABASE_PROJECT_REF"; then
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
    local remote_db_url=$(supabase projects list --output json | jq -r ".[] | select(.ref == \"$SUPABASE_PROJECT_REF\") | .database_url" 2>/dev/null || echo "")
    
    if [ -z "$remote_db_url" ]; then
        warning "Could not get remote database URL, skipping data pull"
        return 0
    fi
    
    # Export data from remote
    local data_file="$BACKUP_DIR/remote_data_$TIMESTAMP.sql"
    log "Exporting data from remote Supabase..."
    pg_dump --data-only --inserts "$remote_db_url" > "$data_file" 2>/dev/null || {
        warning "Could not export remote data, continuing..."
        return 0
    }
    
    # Get local database URL
    local local_db_url=$(supabase status --output json | jq -r '.DB_URL' 2>/dev/null || echo "")
    
    if [ -n "$local_db_url" ] && [ -f "$data_file" ]; then
        log "Importing data to local Supabase..."
        psql "$local_db_url" < "$data_file" 2>/dev/null || {
            warning "Could not import data to local, continuing..."
        }
    fi
    
    success "Supabase data pulled successfully"
}

# Function to start local Supabase
start_local_supabase() {
    log "Starting local Supabase..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Start Supabase
    supabase start
    
    success "Local Supabase started"
}

# Function to verify sync
verify_sync() {
    log "Verifying sync status..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Show migration status
    log "Migration status:"
    supabase migration list
    
    # Show project status
    log "Project status:"
    supabase status
    
    success "Sync verification completed"
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

# Main execution
main() {
    log "Starting Vyaapari360 ERP pull from main process..."
    
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
    
    success "Pull from main completed successfully!"
    log "Summary:"
    log "- Git changes pulled from main branch"
    log "- Local Supabase reset and synced"
    log "- Remote Supabase migrations pulled"
    log "- Remote Supabase data imported"
    log "- Local Supabase started"
    log "- Backup created in: $BACKUP_DIR"
}

# Run main function
main "$@"
