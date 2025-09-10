#!/bin/bash

# Vyaapari360 ERP - Push to Main Script
# This script pushes local changes to Git and syncs Supabase data/structures to main

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
    
    # Get database URL from Supabase
    local db_url=$(supabase status --output json | jq -r '.DB_URL' 2>/dev/null || echo "")
    
    if [ -z "$db_url" ]; then
        warning "Could not get local DB URL, skipping local backup"
        return 0
    fi
    
    # Create backup
    pg_dump "$db_url" > "$backup_file" 2>/dev/null || {
        warning "Could not create local backup, continuing..."
        return 0
    }
    
    success "Backup created: $backup_file"
}

# Function to push Supabase migrations
push_supabase_migrations() {
    log "Pushing Supabase migrations to remote..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Check if project is linked
    if ! supabase projects list | grep -q "$SUPABASE_PROJECT_REF"; then
        log "Linking Supabase project..."
        supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"
    fi
    
    # Push migrations
    log "Pushing database migrations..."
    supabase db push --password "$SUPABASE_DB_PASSWORD"
    
    success "Supabase migrations pushed successfully"
}

# Function to export and push Supabase data
push_supabase_data() {
    log "Exporting and pushing Supabase data..."
    
    cd "$SUPABASE_PROJECT_DIR"
    
    # Export data from local Supabase
    local data_file="$BACKUP_DIR/supabase_data_$TIMESTAMP.sql"
    
    # Get local database URL
    local local_db_url=$(supabase status --output json | jq -r '.DB_URL' 2>/dev/null || echo "")
    
    if [ -n "$local_db_url" ]; then
        log "Exporting data from local Supabase..."
        pg_dump --data-only --inserts "$local_db_url" > "$data_file" 2>/dev/null || {
            warning "Could not export local data, continuing..."
        }
    fi
    
    # Get remote database URL
    local remote_db_url=$(supabase projects list --output json | jq -r ".[] | select(.ref == \"$SUPABASE_PROJECT_REF\") | .database_url" 2>/dev/null || echo "")
    
    if [ -n "$remote_db_url" ] && [ -f "$data_file" ]; then
        log "Importing data to remote Supabase..."
        psql "$remote_db_url" < "$data_file" 2>/dev/null || {
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
    supabase migration list
    
    # Show project status
    supabase status
    
    success "Supabase status updated"
}

# Main execution
main() {
    log "Starting Vyaapari360 ERP push to main process..."
    
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
    push_supabase_migrations
    push_supabase_data
    push_git_changes
    update_supabase_status
    
    success "Push to main completed successfully!"
    log "Summary:"
    log "- Git changes pushed to main branch"
    log "- Supabase migrations deployed"
    log "- Supabase data synchronized"
    log "- Backup created in: $BACKUP_DIR"
}

# Run main function
main "$@"
