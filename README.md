# Lovable Supabase Sync

A powerful, reusable tool for synchronizing any Git repository with any Supabase project. This tool provides automated conflict resolution, Docker management, and comprehensive health monitoring for seamless development workflows.

## 🚀 Features

### Core Functionality
- **Git + Supabase Synchronization** - Push/pull changes with full database sync
- **Automatic Conflict Resolution** - Smart handling of merge conflicts
- **Docker Management** - Automatic container cleanup and restart
- **Health Monitoring** - Comprehensive service health checks
- **Backup & Restore** - Automatic backups with restore capabilities

### Advanced Features
- **Port Conflict Resolution** - Automatic handling of port conflicts
- **Migration Management** - Safe migration deployment and rollback
- **Data Synchronization** - Bidirectional data sync between local and remote
- **Error Recovery** - Automatic cleanup and recovery on failures
- **Configuration Management** - Flexible project-specific configuration

## 📦 Installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/rneelappa/lovable-supabase-sync.git
cd lovable-supabase-sync

# Install in your project
./install.sh --project-dir /path/to/your/project \
             --git-url https://github.com/your-username/your-repo.git \
             --supabase-ref your-supabase-ref \
             --supabase-password your-password
```

### Manual Install

1. **Copy the tool to your project:**
   ```bash
   cp -r lovable-supabase-sync/.supabase-sync /path/to/your/project/
   ```

2. **Configure your project:**
   ```bash
   cp .supabase-sync/config/project-config.example.sh .supabase-sync/config/project-config.sh
   # Edit the configuration file
   ```

3. **Make scripts executable:**
   ```bash
   chmod +x .supabase-sync/scripts/*.sh
   ```

## ⚙️ Configuration

Edit `.supabase-sync/config/project-config.sh` to configure your project:

```bash
# Project Information
PROJECT_NAME="My Awesome Project"
GIT_REMOTE_URL="https://github.com/your-username/your-repo.git"
GIT_BRANCH="main"

# Supabase Configuration
SUPABASE_PROJECT_REF="your-supabase-project-ref"
SUPABASE_DB_PASSWORD="your-supabase-password"
SUPABASE_PROJECT_DIR="supabase"

# Advanced Configuration
CONFLICT_RESOLUTION_STRATEGY="smart"
BACKUP_STRATEGY="full"
MIGRATION_STRATEGY="safe"
DATA_SYNC_STRATEGY="bidirectional"
```

## 🎯 Usage

### Basic Commands

```bash
# Setup and configuration
./supabase-sync.sh setup
./supabase-sync.sh config
./supabase-sync.sh validate

# Sync operations
./supabase-sync.sh push    # Push changes to main
./supabase-sync.sh pull    # Pull latest from main
./supabase-sync.sh status  # Show current status

# Backup and restore
./supabase-sync.sh backup
./supabase-sync.sh restore backup.sql

# Maintenance
./supabase-sync.sh reset   # Reset local Supabase
```

### Convenience Aliases

Source the aliases for quick access:

```bash
source .supabase-sync/aliases.sh

# Now you can use:
supabase-push
supabase-pull
supabase-status
supabase-backup
```

## 🔧 Advanced Configuration

### Conflict Resolution

Configure how conflicts are resolved:

```bash
# File-specific conflict resolution
declare -A CONFLICT_RESOLUTION=(
    ["supabase/config.toml"]="local"
    [".env"]="local"
    ["supabase/migrations/*"]="remote"
    ["package.json"]="local"
    ["*.md"]="local"
)
```

### Backup Strategy

Choose your backup approach:

- `full` - Complete database backup
- `incremental` - Only changed data
- `schema-only` - Database structure only
- `data-only` - Data without structure

### Migration Strategy

Control migration behavior:

- `safe` - Interactive confirmation for dangerous operations
- `force` - Automatic execution without confirmation
- `interactive` - Always ask for confirmation

## 🛡️ Safety Features

### Automatic Backups
- **Before every operation** - Automatic timestamped backups
- **Configurable retention** - Keep backups for specified days
- **Multiple strategies** - Full, incremental, schema-only, data-only

### Error Handling
- **Automatic cleanup** - Clean up on failures
- **Rollback capabilities** - Safe recovery from errors
- **Detailed logging** - Comprehensive error reporting

### Health Monitoring
- **API health checks** - Verify Supabase API availability
- **Database validation** - Ensure database connectivity
- **Service monitoring** - Check all Supabase services

## 📊 Project Structure

```
your-project/
├── .supabase-sync/
│   ├── scripts/
│   │   ├── supabase-sync.sh          # Main sync script
│   │   ├── push-to-main-enhanced.sh  # Enhanced push script
│   │   ├── pull-from-main-enhanced.sh # Enhanced pull script
│   │   └── supabase-utils.sh         # Utility functions
│   ├── config/
│   │   ├── project-config.sh         # Your project configuration
│   │   └── project-config.example.sh # Example configuration
│   ├── backups/                      # Automatic backups
│   └── logs/                         # Log files
├── supabase/                         # Your Supabase project
└── supabase-sync.sh                  # Convenience script
```

## 🔍 Troubleshooting

### Common Issues

1. **Docker not running:**
   ```bash
   # The tool will automatically start Docker Desktop on macOS
   # On Linux, start Docker manually: sudo systemctl start docker
   ```

2. **Port conflicts:**
   ```bash
   # The tool automatically handles port conflicts
   # If issues persist, check what's using the ports:
   lsof -i :54321  # API port
   lsof -i :54322  # Database port
   ```

3. **Configuration errors:**
   ```bash
   # Validate your configuration:
   ./supabase-sync.sh validate
   ```

4. **Permission issues:**
   ```bash
   # Make scripts executable:
   chmod +x .supabase-sync/scripts/*.sh
   ```

### Recovery

If something goes wrong:

1. **Check backups:**
   ```bash
   ls -la .supabase-sync/backups/
   ```

2. **Restore from backup:**
   ```bash
   ./supabase-sync.sh restore .supabase-sync/backups/latest_backup.sql
   ```

3. **Reset to clean state:**
   ```bash
   ./supabase-sync.sh reset
   ```

## 📚 Examples

### Example 1: Basic Project Setup

```bash
# 1. Install the tool
./install.sh --project-dir ./my-project \
             --git-url https://github.com/user/my-project.git \
             --supabase-ref abc123def456 \
             --supabase-password mypassword

# 2. Configure and validate
cd my-project
./supabase-sync.sh config
./supabase-sync.sh validate

# 3. Start syncing
./supabase-sync.sh pull
```

### Example 2: Custom Configuration

```bash
# Edit configuration
nano .supabase-sync/config/project-config.sh

# Set custom conflict resolution
CONFLICT_RESOLUTION_STRATEGY="manual"
BACKUP_STRATEGY="incremental"
MIGRATION_STRATEGY="interactive"

# Apply configuration
./supabase-sync.sh validate
```

### Example 3: Automated Workflow

```bash
# Create a workflow script
cat > sync-workflow.sh << 'EOF'
#!/bin/bash
source .supabase-sync/aliases.sh

# Pull latest changes
supabase-pull

# Make your changes
# ... your development work ...

# Push changes
supabase-push
EOF

chmod +x sync-workflow.sh
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check this README and inline help
- **Issues**: Report issues on GitHub
- **Discussions**: Use GitHub Discussions for questions

## 🎉 Acknowledgments

- Built for the Supabase community
- Inspired by modern DevOps practices
- Designed for developer productivity

---

**Made with ❤️ for the Supabase community**
