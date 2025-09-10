#!/bin/bash

# Vyaapari360 ERP - Setup Script
# Sets up environment and validates prerequisites

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/Users/rajkumarneelappa/Documents/vyaapari-360-erp"
SUPABASE_PROJECT_REF="hycyhnjsldiokfkpqzoz"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing_commands=()
    
    # Check Git
    if command_exists git; then
        success "Git: $(git --version)"
    else
        missing_commands+=("git")
    fi
    
    # Check Supabase CLI
    if command_exists supabase; then
        success "Supabase CLI: $(supabase --version)"
    else
        missing_commands+=("supabase")
        warning "Install with: npm install -g supabase"
    fi
    
    # Check PostgreSQL client
    if command_exists psql; then
        success "PostgreSQL client: $(psql --version)"
    else
        missing_commands+=("psql")
        warning "Install with: brew install postgresql"
    fi
    
    # Check jq
    if command_exists jq; then
        success "jq: $(jq --version)"
    else
        missing_commands+=("jq")
        warning "Install with: brew install jq"
    fi
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        error "Missing required commands: ${missing_commands[*]}"
        echo ""
        echo "Installation commands:"
        echo "  brew install git postgresql jq"
        echo "  npm install -g supabase"
        return 1
    fi
    
    success "All prerequisites met"
}

# Function to setup environment
setup_environment() {
    log "Setting up environment..."
    
    # Create backup directory
    mkdir -p "$PROJECT_ROOT/backups/supabase"
    success "Backup directory created"
    
    # Check if .env file exists
    local env_file="$PROJECT_ROOT/.env"
    if [ ! -f "$env_file" ]; then
        log "Creating .env file template..."
        cat > "$env_file" << EOF
# Vyaapari360 ERP Environment Variables
# Copy this file to .env.local and fill in your values

# Supabase Configuration
SUPABASE_DB_PASSWORD=your_supabase_password_here
SUPABASE_PROJECT_REF=hycyhnjsldiokfkpqzoz

# Optional: Custom paths
# PROJECT_ROOT=/path/to/your/project
# BACKUP_DIR=/path/to/backups
EOF
        success "Created .env template: $env_file"
        warning "Please edit $env_file and set your Supabase password"
    else
        success "Environment file exists: $env_file"
    fi
}

# Function to validate Supabase connection
validate_supabase() {
    log "Validating Supabase connection..."
    
    if [ -z "$SUPABASE_DB_PASSWORD" ]; then
        warning "SUPABASE_DB_PASSWORD not set, skipping validation"
        return 0
    fi
    
    cd "$PROJECT_ROOT/vyaapari-nexus"
    
    # Check if project is linked
    if supabase projects list | grep -q "$SUPABASE_PROJECT_REF"; then
        success "Supabase project is linked"
    else
        warning "Supabase project not linked"
        log "Run: supabase link --project-ref $SUPABASE_PROJECT_REF"
    fi
    
    # Test connection
    if supabase status >/dev/null 2>&1; then
        success "Supabase connection validated"
    else
        warning "Could not validate Supabase connection"
    fi
}

# Function to show usage instructions
show_usage() {
    log "Setup completed! Next steps:"
    echo ""
    echo "1. Set your Supabase password:"
    echo "   export SUPABASE_DB_PASSWORD='your_password'"
    echo ""
    echo "2. Or edit the .env file:"
    echo "   nano $PROJECT_ROOT/.env"
    echo ""
    echo "3. Test the sync system:"
    echo "   ./scripts/sync.sh status"
    echo ""
    echo "4. Available commands:"
    echo "   ./scripts/sync.sh push    # Push changes to main"
    echo "   ./scripts/sync.sh pull    # Pull latest from main"
    echo "   ./scripts/sync.sh backup  # Create backup"
    echo ""
    echo "5. For help:"
    echo "   ./scripts/sync.sh --help"
}

# Function to create aliases
create_aliases() {
    log "Creating convenient aliases..."
    
    local alias_file="$HOME/.vyaapari360_aliases"
    
    cat > "$alias_file" << EOF
# Vyaapari360 ERP Aliases
# Source this file with: source ~/.vyaapari360_aliases

# Sync commands
alias vyaapari-push='cd $PROJECT_ROOT && ./scripts/sync.sh push'
alias vyaapari-pull='cd $PROJECT_ROOT && ./scripts/sync.sh pull'
alias vyaapari-status='cd $PROJECT_ROOT && ./scripts/sync.sh status'
alias vyaapari-backup='cd $PROJECT_ROOT && ./scripts/sync.sh backup'

# Quick navigation
alias vyaapari='cd $PROJECT_ROOT'
alias vyaapari-nexus='cd $PROJECT_ROOT/vyaapari-nexus'
alias vyaapari-tally='cd $PROJECT_ROOT/vyaapari360-tally'
EOF
    
    success "Aliases created: $alias_file"
    log "To use aliases, run: source ~/.vyaapari360_aliases"
}

# Main execution
main() {
    log "Vyaapari360 ERP Setup"
    log "===================="
    
    # Check prerequisites
    if ! check_prerequisites; then
        error "Prerequisites check failed"
        exit 1
    fi
    
    # Setup environment
    setup_environment
    
    # Validate Supabase (if password is set)
    validate_supabase
    
    # Create aliases
    create_aliases
    
    # Show usage
    show_usage
    
    success "Setup completed successfully!"
}

# Run main function
main "$@"
