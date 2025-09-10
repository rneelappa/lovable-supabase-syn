#!/bin/bash

# Lovable Supabase Sync - Installation Script
# This script installs the sync tool in your project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Usage function
usage() {
    echo "Lovable Supabase Sync - Installation Script"
    echo "==========================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --project-dir DIR       Target project directory (default: current directory)"
    echo "  --git-url URL           Git repository URL"
    echo "  --supabase-ref REF      Supabase project reference"
    echo "  --supabase-password PWD Supabase database password"
    echo "  --supabase-dir DIR      Supabase project directory (default: supabase)"
    echo "  --help, -h              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --project-dir /path/to/project"
    echo "  $0 --git-url https://github.com/user/repo.git --supabase-ref abc123"
}

# Parse command line arguments
PROJECT_DIR="."
GIT_URL=""
SUPABASE_REF=""
SUPABASE_PASSWORD=""
SUPABASE_DIR="supabase"

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-dir)
            PROJECT_DIR="$2"
            shift 2
            ;;
        --git-url)
            GIT_URL="$2"
            shift 2
            ;;
        --supabase-ref)
            SUPABASE_REF="$2"
            shift 2
            ;;
        --supabase-password)
            SUPABASE_PASSWORD="$2"
            shift 2
            ;;
        --supabase-dir)
            SUPABASE_DIR="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
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
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        error "Missing required commands: ${missing_commands[*]}"
        echo "Please install the missing commands and try again."
        exit 1
    fi
    
    success "All prerequisites met"
}

# Function to create project structure
create_project_structure() {
    log "Creating project structure..."
    
    # Create directories
    mkdir -p "$PROJECT_DIR/.supabase-sync"
    mkdir -p "$PROJECT_DIR/.supabase-sync/scripts"
    mkdir -p "$PROJECT_DIR/.supabase-sync/config"
    mkdir -p "$PROJECT_DIR/.supabase-sync/backups"
    mkdir -p "$PROJECT_DIR/.supabase-sync/logs"
    
    success "Project structure created"
}

# Function to copy scripts
copy_scripts() {
    log "Copying sync scripts..."
    
    # Copy all scripts
    cp -r "$SCRIPT_DIR/scripts"/* "$PROJECT_DIR/.supabase-sync/scripts/"
    
    # Make scripts executable
    chmod +x "$PROJECT_DIR/.supabase-sync/scripts"/*.sh
    
    success "Scripts copied and made executable"
}

# Function to create configuration
create_configuration() {
    log "Creating configuration..."
    
    # Copy example config
    cp "$SCRIPT_DIR/config/project-config.example.sh" "$PROJECT_DIR/.supabase-sync/config/project-config.sh"
    
    # Update configuration with provided values
    local config_file="$PROJECT_DIR/.supabase-sync/config/project-config.sh"
    
    if [ -n "$GIT_URL" ]; then
        sed -i.bak "s|GIT_REMOTE_URL=\"https://github.com/your-username/your-repo.git\"|GIT_REMOTE_URL=\"$GIT_URL\"|g" "$config_file"
    fi
    
    if [ -n "$SUPABASE_REF" ]; then
        sed -i.bak "s|SUPABASE_PROJECT_REF=\"your-supabase-project-ref\"|SUPABASE_PROJECT_REF=\"$SUPABASE_REF\"|g" "$config_file"
    fi
    
    if [ -n "$SUPABASE_PASSWORD" ]; then
        sed -i.bak "s|SUPABASE_DB_PASSWORD=\"your-supabase-password\"|SUPABASE_DB_PASSWORD=\"$SUPABASE_PASSWORD\"|g" "$config_file"
    fi
    
    if [ -n "$SUPABASE_DIR" ]; then
        sed -i.bak "s|SUPABASE_PROJECT_DIR=\"supabase\"|SUPABASE_PROJECT_DIR=\"$SUPABASE_DIR\"|g" "$config_file"
    fi
    
    # Clean up backup files
    rm -f "$PROJECT_DIR/.supabase-sync/config/project-config.sh.bak"
    
    success "Configuration created"
}

# Function to create convenience scripts
create_convenience_scripts() {
    log "Creating convenience scripts..."
    
    # Create main sync script in project root
    cat > "$PROJECT_DIR/supabase-sync.sh" << 'EOF'
#!/bin/bash
# Convenience script to run Supabase sync
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/.supabase-sync/scripts/supabase-sync.sh" "$@"
EOF
    
    chmod +x "$PROJECT_DIR/supabase-sync.sh"
    
    # Create aliases file
    cat > "$PROJECT_DIR/.supabase-sync/aliases.sh" << 'EOF'
# Lovable Supabase Sync Aliases
# Source this file with: source .supabase-sync/aliases.sh

alias supabase-push='./supabase-sync.sh push'
alias supabase-pull='./supabase-sync.sh pull'
alias supabase-status='./supabase-sync.sh status'
alias supabase-backup='./supabase-sync.sh backup'
alias supabase-config='./supabase-sync.sh config'
alias supabase-validate='./supabase-sync.sh validate'
EOF
    
    success "Convenience scripts created"
}

# Function to create documentation
create_documentation() {
    log "Creating documentation..."
    
    # Create README for the project
    cat > "$PROJECT_DIR/.supabase-sync/README.md" << 'EOF'
# Lovable Supabase Sync

This project has been configured with Lovable Supabase Sync for automated Git and Supabase synchronization.

## Quick Start

1. **Configure your project:**
   ```bash
   ./supabase-sync.sh config
   ```

2. **Validate configuration:**
   ```bash
   ./supabase-sync.sh validate
   ```

3. **Check status:**
   ```bash
   ./supabase-sync.sh status
   ```

4. **Sync with main:**
   ```bash
   ./supabase-sync.sh pull
   ./supabase-sync.sh push
   ```

## Available Commands

- `./supabase-sync.sh push` - Push changes to main
- `./supabase-sync.sh pull` - Pull latest from main
- `./supabase-sync.sh status` - Show current status
- `./supabase-sync.sh backup` - Create backup
- `./supabase-sync.sh restore <file>` - Restore from backup
- `./supabase-sync.sh reset` - Reset local Supabase
- `./supabase-sync.sh config` - Show configuration
- `./supabase-sync.sh validate` - Validate configuration

## Configuration

Edit `.supabase-sync/config/project-config.sh` to customize settings.

## Aliases

Source `.supabase-sync/aliases.sh` for convenient aliases:

```bash
source .supabase-sync/aliases.sh
```

Then use:
- `supabase-push`
- `supabase-pull`
- `supabase-status`
- etc.

## Documentation

For complete documentation, see the original repository:
https://github.com/rneelappa/lovable-supabase-sync
EOF
    
    success "Documentation created"
}

# Function to validate installation
validate_installation() {
    log "Validating installation..."
    
    cd "$PROJECT_DIR"
    
    # Check if main script works
    if ./supabase-sync.sh validate; then
        success "Installation validated successfully"
    else
        warning "Installation completed but validation failed"
        echo "Please check your configuration in .supabase-sync/config/project-config.sh"
    fi
}

# Main execution
main() {
    log "Lovable Supabase Sync - Installation"
    log "===================================="
    
    # Check prerequisites
    check_prerequisites
    
    # Create project structure
    create_project_structure
    
    # Copy scripts
    copy_scripts
    
    # Create configuration
    create_configuration
    
    # Create convenience scripts
    create_convenience_scripts
    
    # Create documentation
    create_documentation
    
    # Validate installation
    validate_installation
    
    success "Installation completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Review configuration: ./supabase-sync.sh config"
    echo "2. Validate setup: ./supabase-sync.sh validate"
    echo "3. Check status: ./supabase-sync.sh status"
    echo "4. Start syncing: ./supabase-sync.sh pull"
    echo ""
    echo "For convenience, source the aliases:"
    echo "  source .supabase-sync/aliases.sh"
}

# Run main function
main "$@"
