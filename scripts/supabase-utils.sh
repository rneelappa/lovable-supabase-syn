#!/bin/bash

# Vyaapari360 ERP - Supabase Utility Functions
# Common functions for Supabase operations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SUPABASE_PROJECT_REF="hycyhnjsldiokfkpqzoz"
BACKUP_DIR="/Users/rajkumarneelappa/Documents/vyaapari-360-erp/backups/supabase"

# Logging functions
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

# Function to check if Supabase CLI is installed
check_supabase_cli() {
    if ! command -v supabase >/dev/null 2>&1; then
        error "Supabase CLI is not installed"
        echo "Install it with: npm install -g supabase"
        exit 1
    fi
}

# Function to check if project is linked
is_project_linked() {
    supabase projects list | grep -q "$SUPABASE_PROJECT_REF" 2>/dev/null
}

# Function to link project if not linked
ensure_project_linked() {
    if ! is_project_linked; then
        log "Linking Supabase project..."
        supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"
        success "Project linked successfully"
    else
        log "Project already linked"
    fi
}

# Function to get local database URL
get_local_db_url() {
    supabase status --output json 2>/dev/null | jq -r '.DB_URL' 2>/dev/null || echo ""
}

# Function to get remote database URL
get_remote_db_url() {
    supabase projects list --output json 2>/dev/null | jq -r ".[] | select(.ref == \"$SUPABASE_PROJECT_REF\") | .database_url" 2>/dev/null || echo ""
}

# Function to create database backup
create_db_backup() {
    local db_url="$1"
    local backup_file="$2"
    
    if [ -z "$db_url" ]; then
        warning "No database URL provided for backup"
        return 1
    fi
    
    log "Creating database backup..."
    pg_dump "$db_url" > "$backup_file" 2>/dev/null || {
        error "Failed to create database backup"
        return 1
    }
    
    success "Database backup created: $backup_file"
    return 0
}

# Function to restore database from backup
restore_db_backup() {
    local db_url="$1"
    local backup_file="$2"
    
    if [ -z "$db_url" ]; then
        warning "No database URL provided for restore"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring database from backup..."
    psql "$db_url" < "$backup_file" 2>/dev/null || {
        error "Failed to restore database from backup"
        return 1
    }
    
    success "Database restored from backup: $backup_file"
    return 0
}

# Function to export data only (no schema)
export_data_only() {
    local db_url="$1"
    local data_file="$2"
    
    if [ -z "$db_url" ]; then
        warning "No database URL provided for data export"
        return 1
    fi
    
    log "Exporting data only..."
    pg_dump --data-only --inserts "$db_url" > "$data_file" 2>/dev/null || {
        error "Failed to export data"
        return 1
    }
    
    success "Data exported: $data_file"
    return 0
}

# Function to import data only
import_data_only() {
    local db_url="$1"
    local data_file="$2"
    
    if [ -z "$db_url" ]; then
        warning "No database URL provided for data import"
        return 1
    fi
    
    if [ ! -f "$data_file" ]; then
        error "Data file not found: $data_file"
        return 1
    fi
    
    log "Importing data..."
    psql "$db_url" < "$data_file" 2>/dev/null || {
        error "Failed to import data"
        return 1
    }
    
    success "Data imported: $data_file"
    return 0
}

# Function to check migration status
check_migration_status() {
    log "Checking migration status..."
    supabase migration list
}

# Function to show project status
show_project_status() {
    log "Project status:"
    supabase status
}

# Function to create timestamped backup filename
create_backup_filename() {
    local prefix="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    echo "$BACKUP_DIR/${prefix}_${timestamp}.sql"
}

# Function to ensure backup directory exists
ensure_backup_dir() {
    mkdir -p "$BACKUP_DIR"
}

# Function to validate database connection
validate_db_connection() {
    local db_url="$1"
    
    if [ -z "$db_url" ]; then
        return 1
    fi
    
    psql "$db_url" -c "SELECT 1;" >/dev/null 2>&1
}

# Function to get database size
get_db_size() {
    local db_url="$1"
    
    if [ -z "$db_url" ]; then
        echo "Unknown"
        return 1
    fi
    
    psql "$db_url" -t -c "SELECT pg_size_pretty(pg_database_size(current_database()));" 2>/dev/null | tr -d ' ' || echo "Unknown"
}

# Function to list all tables
list_tables() {
    local db_url="$1"
    
    if [ -z "$db_url" ]; then
        return 1
    fi
    
    psql "$db_url" -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" 2>/dev/null | tr -d ' '
}

# Function to get table row count
get_table_row_count() {
    local db_url="$1"
    local table_name="$2"
    
    if [ -z "$db_url" ] || [ -z "$table_name" ]; then
        return 1
    fi
    
    psql "$db_url" -t -c "SELECT COUNT(*) FROM $table_name;" 2>/dev/null | tr -d ' '
}

# Function to show database summary
show_db_summary() {
    local db_url="$1"
    
    if [ -z "$db_url" ]; then
        warning "No database URL provided"
        return 1
    fi
    
    log "Database Summary:"
    log "=================="
    log "Size: $(get_db_size "$db_url")"
    log "Tables:"
    
    local tables=$(list_tables "$db_url")
    for table in $tables; do
        local count=$(get_table_row_count "$db_url" "$table")
        log "  - $table: $count rows"
    done
}

# Docker management functions
# Function to check if Docker is running
is_docker_running() {
    docker info >/dev/null 2>&1
}

# Function to restart Docker if needed
restart_docker_if_needed() {
    if ! is_docker_running; then
        log "Docker is not running, attempting to start..."
        if command -v open >/dev/null 2>&1; then
            open -a Docker
            log "Docker Desktop started, waiting for it to be ready..."
            local max_attempts=30
            local attempt=0
            while [ $attempt -lt $max_attempts ]; do
                if is_docker_running; then
                    success "Docker is now running"
                    return 0
                fi
                sleep 2
                attempt=$((attempt + 1))
            done
            error "Docker failed to start after $max_attempts attempts"
            return 1
        else
            error "Docker is not running and cannot start it automatically"
            return 1
        fi
    fi
    return 0
}

# Function to clean up Docker containers
cleanup_docker_containers() {
    log "Cleaning up Docker containers..."
    
    # Stop and remove Supabase containers
    docker ps -a --filter "label=com.supabase.cli.project" --format "{{.Names}}" | xargs -r docker stop
    docker ps -a --filter "label=com.supabase.cli.project" --format "{{.Names}}" | xargs -r docker rm
    
    # Clean up orphaned containers
    docker container prune -f >/dev/null 2>&1
    
    success "Docker containers cleaned up"
}

# Function to handle Supabase port conflicts
handle_port_conflicts() {
    local port="$1"
    local service_name="$2"
    
    if [ -z "$port" ] || [ -z "$service_name" ]; then
        return 0
    fi
    
    # Check if port is in use
    if lsof -i ":$port" >/dev/null 2>&1; then
        log "Port $port is in use, attempting to free it..."
        
        # Try to stop Supabase first
        supabase stop 2>/dev/null || true
        
        # Wait a moment
        sleep 2
        
        # Check again
        if lsof -i ":$port" >/dev/null 2>&1; then
            warning "Port $port is still in use, you may need to manually stop the process"
            return 1
        fi
    fi
    
    return 0
}

# Function to resolve Supabase merge conflicts
resolve_supabase_conflicts() {
    local project_dir="$1"
    
    if [ -z "$project_dir" ]; then
        error "Project directory not provided for conflict resolution"
        return 1
    fi
    
    cd "$project_dir"
    
    # Check for merge conflicts in Supabase files
    local conflict_files=$(git diff --name-only --diff-filter=U | grep -E "(supabase/|\.env)" || true)
    
    if [ -n "$conflict_files" ]; then
        log "Resolving Supabase merge conflicts..."
        
        for file in $conflict_files; do
            log "Resolving conflicts in: $file"
            
            # For Supabase config files, prefer local version
            if [[ "$file" == "supabase/config.toml" ]]; then
                git checkout --ours "$file"
                git add "$file"
                log "Resolved $file using local version"
            # For .env files, prefer local version but merge carefully
            elif [[ "$file" == ".env" ]]; then
                git checkout --ours "$file"
                git add "$file"
                log "Resolved $file using local version"
            # For migration files, prefer remote version
            elif [[ "$file" == supabase/migrations/* ]]; then
                git checkout --theirs "$file"
                git add "$file"
                log "Resolved $file using remote version"
            else
                # Default to local version
                git checkout --ours "$file"
                git add "$file"
                log "Resolved $file using local version"
            fi
        done
        
        # Commit the resolved conflicts
        git commit -m "Resolve Supabase merge conflicts - $(date +'%Y-%m-%d %H:%M:%S')"
        success "Supabase merge conflicts resolved"
    else
        log "No Supabase merge conflicts found"
    fi
    
    return 0
}

# Function to force restart Supabase
force_restart_supabase() {
    local project_dir="$1"
    
    if [ -z "$project_dir" ]; then
        error "Project directory not provided for Supabase restart"
        return 1
    fi
    
    cd "$project_dir"
    
    log "Force restarting Supabase..."
    
    # Stop Supabase forcefully
    supabase stop --no-backup 2>/dev/null || true
    
    # Clean up Docker containers
    cleanup_docker_containers
    
    # Handle port conflicts
    handle_port_conflicts 54321 "API"
    handle_port_conflicts 54322 "Database"
    handle_port_conflicts 54323 "Studio"
    
    # Wait a moment
    sleep 3
    
    # Start Supabase
    if supabase start; then
        success "Supabase restarted successfully"
        return 0
    else
        error "Failed to restart Supabase"
        return 1
    fi
}

# Function to check Supabase health
check_supabase_health() {
    local project_dir="$1"
    
    if [ -z "$project_dir" ]; then
        error "Project directory not provided for health check"
        return 1
    fi
    
    cd "$project_dir"
    
    # Check if Supabase is running
    if ! supabase status >/dev/null 2>&1; then
        warning "Supabase is not running"
        return 1
    fi
    
    # Check API health
    local api_url=$(supabase status --output json 2>/dev/null | jq -r '.API_URL' 2>/dev/null || echo "")
    if [ -n "$api_url" ]; then
        if curl -s "$api_url/health" >/dev/null 2>&1; then
            success "Supabase API is healthy"
        else
            warning "Supabase API health check failed"
            return 1
        fi
    fi
    
    # Check database connection
    local db_url=$(get_local_db_url)
    if [ -n "$db_url" ] && validate_db_connection "$db_url"; then
        success "Supabase database is healthy"
    else
        warning "Supabase database health check failed"
        return 1
    fi
    
    return 0
}

# Export functions for use in other scripts
export -f log error success warning
export -f check_supabase_cli is_project_linked ensure_project_linked
export -f get_local_db_url get_remote_db_url
export -f create_db_backup restore_db_backup
export -f export_data_only import_data_only
export -f check_migration_status show_project_status
export -f create_backup_filename ensure_backup_dir
export -f validate_db_connection get_db_size list_tables get_table_row_count show_db_summary
export -f is_docker_running restart_docker_if_needed cleanup_docker_containers
export -f handle_port_conflicts resolve_supabase_conflicts force_restart_supabase check_supabase_health
