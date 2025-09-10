#!/bin/bash

# Vyaapari360 ERP - Main Sync Script
# Unified script for both push and pull operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utility functions
source "$SCRIPT_DIR/supabase-utils.sh"

# Usage function
usage() {
    echo "Vyaapari360 ERP Sync Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  push                    Push local changes to main (Git + Supabase)"
    echo "  pull                    Pull latest changes from main (Git + Supabase)"
    echo "  status                  Show current sync status"
    echo "  backup                  Create backup of current state"
    echo "  restore [backup_file]   Restore from backup"
    echo "  reset                   Reset local Supabase to match remote"
    echo ""
    echo "Options:"
    echo "  --help, -h              Show this help message"
    echo "  --dry-run               Show what would be done without executing"
    echo "  --force                 Force operation without confirmation"
    echo ""
    echo "Environment Variables:"
    echo "  SUPABASE_DB_PASSWORD    Required: Supabase database password"
    echo ""
    echo "Examples:"
    echo "  $0 push                 # Push changes to main"
    echo "  $0 pull                 # Pull latest from main"
    echo "  $0 status               # Show current status"
    echo "  $0 backup               # Create backup"
    echo "  $0 restore backup.sql   # Restore from backup"
}

# Parse command line arguments
COMMAND=""
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        push|pull|status|backup|restore|reset)
            COMMAND="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            if [[ "$COMMAND" == "restore" && -z "$RESTORE_FILE" ]]; then
                RESTORE_FILE="$1"
            else
                error "Unknown option: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if command is provided
if [ -z "$COMMAND" ]; then
    error "No command provided"
    usage
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check required commands
    local missing_commands=()
    
    if ! command -v git >/dev/null 2>&1; then
        missing_commands+=("git")
    fi
    
    if ! command -v supabase >/dev/null 2>&1; then
        missing_commands+=("supabase")
    fi
    
    if ! command -v psql >/dev/null 2>&1; then
        missing_commands+=("psql")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_commands+=("jq")
    fi
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        error "Missing required commands: ${missing_commands[*]}"
        echo "Please install the missing commands and try again."
        exit 1
    fi
    
    # Check environment variables
    if [ -z "$SUPABASE_DB_PASSWORD" ]; then
        error "SUPABASE_DB_PASSWORD environment variable is required"
        echo "Please set it with: export SUPABASE_DB_PASSWORD='your_password'"
        exit 1
    fi
    
    success "All prerequisites met"
}

# Execute command with dry-run check
execute_command() {
    local cmd="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would execute: $description"
        log "[DRY RUN] Command: $cmd"
        return 0
    fi
    
    log "Executing: $description"
    eval "$cmd"
}

# Push command
push_command() {
    log "Starting push operation..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would push Git changes and sync Supabase"
        return 0
    fi
    
    # Execute enhanced push script
    execute_command "$SCRIPT_DIR/push-to-main-enhanced.sh" "Enhanced push to main script"
}

# Pull command
pull_command() {
    log "Starting pull operation..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would pull Git changes and sync Supabase"
        return 0
    fi
    
    # Execute enhanced pull script
    execute_command "$SCRIPT_DIR/pull-from-main-enhanced.sh" "Enhanced pull from main script"
}

# Status command
status_command() {
    log "Checking sync status..."
    
    cd "$PROJECT_ROOT"
    
    # Git status
    log "Git Status:"
    echo "==========="
    git status --short
    echo ""
    
    # Supabase status
    cd "$PROJECT_ROOT/vyaapari-nexus"
    log "Supabase Status:"
    echo "==============="
    show_project_status
    echo ""
    
    # Migration status
    log "Migration Status:"
    echo "================"
    check_migration_status
    echo ""
    
    # Database summary
    local local_db_url=$(get_local_db_url)
    if [ -n "$local_db_url" ]; then
        log "Local Database Summary:"
        echo "======================"
        show_db_summary "$local_db_url"
    fi
}

# Backup command
backup_command() {
    log "Creating backup..."
    
    ensure_backup_dir
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file=$(create_backup_filename "full_backup_$timestamp")
    
    cd "$PROJECT_ROOT/vyaapari-nexus"
    
    # Backup local database
    local local_db_url=$(get_local_db_url)
    if [ -n "$local_db_url" ]; then
        create_db_backup "$local_db_url" "$backup_file"
    else
        warning "Could not get local database URL, skipping backup"
    fi
    
    # Backup Git state
    cd "$PROJECT_ROOT"
    local git_backup_file="$BACKUP_DIR/git_state_$timestamp.txt"
    git log --oneline -10 > "$git_backup_file"
    git status > "${git_backup_file}.status"
    
    success "Backup completed: $backup_file"
}

# Restore command
restore_command() {
    if [ -z "$RESTORE_FILE" ]; then
        error "No backup file specified for restore"
        echo "Usage: $0 restore <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$RESTORE_FILE" ]; then
        error "Backup file not found: $RESTORE_FILE"
        exit 1
    fi
    
    log "Restoring from backup: $RESTORE_FILE"
    
    cd "$PROJECT_ROOT/vyaapari-nexus"
    
    # Restore database
    local local_db_url=$(get_local_db_url)
    if [ -n "$local_db_url" ]; then
        restore_db_backup "$local_db_url" "$RESTORE_FILE"
    else
        error "Could not get local database URL for restore"
        exit 1
    fi
    
    success "Restore completed"
}

# Reset command
reset_command() {
    log "Resetting local Supabase to match remote..."
    
    if [ "$FORCE" != true ]; then
        read -p "This will reset your local Supabase database. Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Reset cancelled"
            exit 0
        fi
    fi
    
    cd "$PROJECT_ROOT/vyaapari-nexus"
    
    # Stop local Supabase
    supabase stop 2>/dev/null || true
    
    # Reset database
    supabase db reset --linked
    
    # Start Supabase
    supabase start
    
    success "Reset completed"
}

# Main execution
main() {
    log "Vyaapari360 ERP Sync Script"
    log "=========================="
    
    # Check prerequisites
    check_prerequisites
    
    # Execute command
    case "$COMMAND" in
        push)
            push_command
            ;;
        pull)
            pull_command
            ;;
        status)
            status_command
            ;;
        backup)
            backup_command
            ;;
        restore)
            restore_command
            ;;
        reset)
            reset_command
            ;;
        *)
            error "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
    
    success "Operation completed successfully!"
}

# Run main function
main "$@"
