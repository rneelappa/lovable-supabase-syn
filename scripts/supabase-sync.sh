#!/bin/bash

# Lovable Supabase Sync - Main Sync Script
# A reusable tool for syncing any Git repository with any Supabase project

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

# Load project configuration
CONFIG_FILE="$PROJECT_ROOT/config/project-config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    error "Configuration file not found: $CONFIG_FILE"
    echo "Please copy config/project-config.example.sh to config/project-config.sh and configure it"
    exit 1
fi

# Usage function
usage() {
    echo "Lovable Supabase Sync"
    echo "====================="
    echo ""
    echo "A reusable tool for syncing any Git repository with any Supabase project"
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
    echo "  config                  Show current configuration"
    echo "  validate                Validate configuration"
    echo "  setup                   Initial setup and configuration"
    echo ""
    echo "Options:"
    echo "  --help, -h              Show this help message"
    echo "  --dry-run               Show what would be done without executing"
    echo "  --force                 Force operation without confirmation"
    echo "  --config FILE           Use specific configuration file"
    echo ""
    echo "Configuration:"
    echo "  Copy config/project-config.example.sh to config/project-config.sh"
    echo "  and customize it for your project"
    echo ""
    echo "Examples:"
    echo "  $0 push                 # Push changes to main"
    echo "  $0 pull                 # Pull latest from main"
    echo "  $0 status               # Show current status"
    echo "  $0 config               # Show configuration"
    echo "  $0 setup                # Initial setup"
}

# Parse command line arguments
COMMAND=""
DRY_RUN=false
FORCE=false
CONFIG_FILE_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        push|pull|status|backup|restore|reset|config|validate|setup)
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
        --config)
            CONFIG_FILE_OVERRIDE="$2"
            shift 2
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

# Load configuration if override provided
if [ -n "$CONFIG_FILE_OVERRIDE" ]; then
    if [ -f "$CONFIG_FILE_OVERRIDE" ]; then
        source "$CONFIG_FILE_OVERRIDE"
    else
        error "Configuration file not found: $CONFIG_FILE_OVERRIDE"
        exit 1
    fi
fi

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
    
    if ! command -v docker >/dev/null 2>&1; then
        missing_commands+=("docker")
    fi
    
    if ! command -v lsof >/dev/null 2>&1; then
        missing_commands+=("lsof")
    fi
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        error "Missing required commands: ${missing_commands[*]}"
        echo "Please install the missing commands and try again."
        exit 1
    fi
    
    # Check Docker
    if [ "$DOCKER_AUTO_START" = true ] && ! restart_docker_if_needed; then
        error "Docker is required but not available"
        exit 1
    fi
    
    # Validate configuration
    if ! validate_config; then
        error "Configuration validation failed"
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
    
    cd "$GIT_WORKING_DIR"
    
    # Git status
    log "Git Status:"
    echo "==========="
    git status --short
    echo ""
    
    # Supabase status
    cd "$GIT_WORKING_DIR/$SUPABASE_PROJECT_DIR"
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
    
    cd "$GIT_WORKING_DIR/$SUPABASE_PROJECT_DIR"
    
    # Backup local database
    local local_db_url=$(get_local_db_url)
    if [ -n "$local_db_url" ]; then
        create_db_backup "$local_db_url" "$backup_file"
    else
        warning "Could not get local database URL, skipping backup"
    fi
    
    # Backup Git state
    cd "$GIT_WORKING_DIR"
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
    
    cd "$GIT_WORKING_DIR/$SUPABASE_PROJECT_DIR"
    
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
    
    cd "$GIT_WORKING_DIR/$SUPABASE_PROJECT_DIR"
    
    # Stop local Supabase
    supabase stop 2>/dev/null || true
    
    # Reset database
    supabase db reset --linked
    
    # Start Supabase
    supabase start
    
    success "Reset completed"
}

# Config command
config_command() {
    show_config
}

# Validate command
validate_command() {
    log "Validating configuration..."
    validate_config
}

# Setup command
setup_command() {
    log "Setting up Lovable Supabase Sync..."
    
    # Create necessary directories
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Copy example config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ -f "$PROJECT_ROOT/config/project-config.example.sh" ]; then
            cp "$PROJECT_ROOT/config/project-config.example.sh" "$CONFIG_FILE"
            success "Created configuration file: $CONFIG_FILE"
            echo "Please edit $CONFIG_FILE and configure it for your project"
        else
            error "Example configuration file not found"
            exit 1
        fi
    fi
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR"/*.sh
    
    success "Setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Edit $CONFIG_FILE and configure it for your project"
    echo "2. Run: $0 validate to check your configuration"
    echo "3. Run: $0 status to check current status"
}

# Main execution
main() {
    log "Lovable Supabase Sync"
    log "====================="
    
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
        config)
            config_command
            ;;
        validate)
            validate_command
            ;;
        setup)
            setup_command
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
