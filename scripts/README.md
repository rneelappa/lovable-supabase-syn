# Vyaapari360 ERP Sync Scripts

This directory contains scripts for synchronizing your Vyaapari360 ERP system between local development and the main production environment, including both Git operations and Supabase database synchronization.

## Overview

The sync system provides a unified way to:
- Push local changes to main (Git + Supabase data + structures)
- Pull latest changes from main (Git + Supabase data + structures)
- Manage backups and restore operations
- Monitor sync status

## Scripts

### 1. `sync.sh` - Main Sync Script (Recommended)

The primary script that provides a unified interface for all sync operations.

```bash
# Basic usage
./scripts/sync.sh [COMMAND] [OPTIONS]

# Examples
./scripts/sync.sh push                    # Push changes to main
./scripts/sync.sh pull                    # Pull latest from main
./scripts/sync.sh status                  # Show current status
./scripts/sync.sh backup                  # Create backup
./scripts/sync.sh restore backup.sql      # Restore from backup
./scripts/sync.sh reset                   # Reset local to match remote
```

### 2. `push-to-main.sh` - Push Script (Legacy)

Pushes local changes to the main branch and syncs Supabase data/structures.

**Features:**
- Commits and pushes Git changes to main branch
- Pushes Supabase migrations to remote
- Exports local data and imports to remote
- Creates backups before operations
- Handles migration conflicts

### 3. `pull-from-main.sh` - Pull Script (Legacy)

Pulls latest changes from main and syncs Supabase data/structures.

**Features:**
- Pulls Git changes from main branch
- Resets local Supabase to match remote
- Pulls Supabase migrations from remote
- Imports remote data to local
- Handles stashed changes
- Creates backups before operations

### 4. `push-to-main-enhanced.sh` - Enhanced Push Script

Enhanced version with advanced conflict handling and Docker management.

**Features:**
- All features from legacy push script
- **Automatic merge conflict resolution** for Supabase files
- **Docker container management** and cleanup
- **Port conflict handling** (54321, 54322, 54323)
- **Health checks** for Supabase services
- **Force restart** capabilities for Docker issues
- **Enhanced error handling** with cleanup on failure

### 5. `pull-from-main-enhanced.sh` - Enhanced Pull Script

Enhanced version with advanced conflict handling and Docker management.

**Features:**
- All features from legacy pull script
- **Automatic merge conflict resolution** for Supabase files
- **Docker container management** and cleanup
- **Port conflict handling** (54321, 54322, 54323)
- **Health checks** for Supabase services
- **Force restart** capabilities for Docker issues
- **Enhanced error handling** with cleanup on failure

### 6. `supabase-utils.sh` - Utility Functions

Common functions used by other scripts for Supabase operations.

**Features:**
- Database connection management
- Backup and restore operations
- Data export/import functions
- Migration status checking
- Database summary reporting

## Prerequisites

Before using these scripts, ensure you have:

1. **Required Software:**
   - Git
   - Supabase CLI (`npm install -g supabase`)
   - PostgreSQL client (`psql`)
   - jq (JSON processor)

2. **Environment Variables:**
   ```bash
   export SUPABASE_DB_PASSWORD='your_supabase_password'
   ```

3. **Supabase Project:**
   - Project must be linked to remote Supabase instance
   - Project reference: `hycyhnjsldiokfkpqzoz`

## Quick Start

1. **Set up environment:**
   ```bash
   export SUPABASE_DB_PASSWORD='your_password'
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Check status:**
   ```bash
   ./scripts/sync.sh status
   ```

4. **Push changes:**
   ```bash
   ./scripts/sync.sh push
   ```

5. **Pull latest:**
   ```bash
   ./scripts/sync.sh pull
   ```

## Detailed Usage

### Push Operations

When you push changes, the script will:

1. **Git Operations:**
   - Add all changes to Git
   - Commit with timestamp
   - Push to main branch

2. **Supabase Operations:**
   - Create backup of current state
   - Push migrations to remote
   - Export local data
   - Import data to remote

3. **Backup:**
   - Create timestamped backup in `backups/supabase/`

### Pull Operations

When you pull changes, the script will:

1. **Git Operations:**
   - Stash local changes (if any)
   - Pull latest from main branch
   - Optionally restore stashed changes

2. **Supabase Operations:**
   - Create backup of local state
   - Reset local Supabase
   - Pull migrations from remote
   - Export remote data
   - Import data to local
   - Start local Supabase

3. **Backup:**
   - Create timestamped backup in `backups/supabase/`

### Backup and Restore

```bash
# Create backup
./scripts/sync.sh backup

# Restore from backup
./scripts/sync.sh restore backups/supabase/full_backup_20240101_120000.sql
```

### Status Monitoring

```bash
# Show comprehensive status
./scripts/sync.sh status
```

This shows:
- Git status (uncommitted changes)
- Supabase project status
- Migration status
- Database summary (size, tables, row counts)

## Configuration

### Project Configuration

The scripts use these default paths:
- Project Root: `/Users/rajkumarneelappa/Documents/vyaapari-360-erp`
- Supabase Project: `vyaapari-nexus/`
- Backup Directory: `backups/supabase/`
- Supabase Project Ref: `hycyhnjsldiokfkpqzoz`

### Customization

To customize paths, edit the configuration section in each script:

```bash
# In push-to-main.sh, pull-from-main.sh, sync.sh
PROJECT_ROOT="/path/to/your/project"
SUPABASE_PROJECT_DIR="$PROJECT_ROOT/vyaapari-nexus"
SUPABASE_PROJECT_REF="your-project-ref"
BACKUP_DIR="$PROJECT_ROOT/backups/supabase"
```

## Safety Features

### Automatic Backups

All operations create automatic backups:
- Before push operations
- Before pull operations
- Before reset operations
- Timestamped for easy identification

### Dry Run Mode

Test operations without executing:

```bash
./scripts/sync.sh push --dry-run
./scripts/sync.sh pull --dry-run
```

### Force Mode

Skip confirmations for automated operations:

```bash
./scripts/sync.sh reset --force
```

## Enhanced Features (New)

### Automatic Merge Conflict Resolution

The enhanced scripts automatically handle merge conflicts in Supabase files:

- **Config files** (`supabase/config.toml`): Prefers local version
- **Environment files** (`.env`): Prefers local version
- **Migration files** (`supabase/migrations/*`): Prefers remote version
- **Other files**: Prefers local version

### Docker Management

Enhanced Docker container management:

- **Automatic Docker startup** if not running
- **Container cleanup** before operations
- **Port conflict resolution** (54321, 54322, 54323)
- **Force restart** capabilities for stuck containers

### Health Monitoring

Comprehensive health checks:

- **API health** verification
- **Database connection** validation
- **Service status** monitoring
- **Automatic recovery** attempts

### Error Handling

Robust error handling with cleanup:

- **Automatic cleanup** on failure
- **Detailed error logging**
- **Recovery suggestions**
- **Safe rollback** capabilities

## Troubleshooting

### Common Issues

1. **Password Authentication Failed:**
   ```bash
   # Ensure password is set correctly
   export SUPABASE_DB_PASSWORD='correct_password'
   ```

2. **Project Not Linked:**
   ```bash
   # Link project manually
   cd vyaapari-nexus
   supabase link --project-ref hycyhnjsldiokfkpqzoz
   ```

3. **Migration Conflicts:**
   ```bash
   # Repair migration history
   supabase migration repair --status reverted <migration_id>
   ```

4. **Permission Denied:**
   ```bash
   # Make scripts executable
   chmod +x scripts/*.sh
   ```

### Logs and Debugging

Scripts provide detailed logging:
- Timestamped log messages
- Color-coded output (success, warning, error)
- Operation summaries
- Backup file locations

### Recovery

If something goes wrong:

1. **Check backups:**
   ```bash
   ls -la backups/supabase/
   ```

2. **Restore from backup:**
   ```bash
   ./scripts/sync.sh restore backups/supabase/latest_backup.sql
   ```

3. **Reset to remote state:**
   ```bash
   ./scripts/sync.sh reset
   ```

## Best Practices

1. **Always backup before major operations**
2. **Test with dry-run mode first**
3. **Keep your password secure**
4. **Monitor status regularly**
5. **Keep backups organized by date**

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review script logs for error messages
3. Verify all prerequisites are installed
4. Ensure environment variables are set correctly
