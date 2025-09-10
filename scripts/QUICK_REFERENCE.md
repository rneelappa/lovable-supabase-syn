# Vyaapari360 ERP - Quick Reference

## 🚀 Quick Start

```bash
# 1. Setup (one-time)
./scripts/setup.sh

# 2. Set password
export SUPABASE_DB_PASSWORD='your_password'

# 3. Use aliases (optional)
source ~/.vyaapari360_aliases
```

## 📋 Essential Commands

### Main Sync Operations
```bash
# Push changes to main (Git + Supabase)
./scripts/sync.sh push

# Pull latest from main (Git + Supabase)
./scripts/sync.sh pull

# Check current status
./scripts/sync.sh status
```

### Backup & Restore
```bash
# Create backup
./scripts/sync.sh backup

# Restore from backup
./scripts/sync.sh restore backups/supabase/backup_file.sql

# Reset to remote state
./scripts/sync.sh reset
```

### Convenient Aliases (after setup)
```bash
# Quick commands
vyaapari-push      # Push to main
vyaapari-pull      # Pull from main
vyaapari-status    # Show status
vyaapari-backup    # Create backup

# Navigation
vyaapari           # Go to project root
vyaapari-nexus     # Go to nexus directory
vyaapari-tally     # Go to tally directory
```

## 🔧 Advanced Options

### Dry Run (Test without executing)
```bash
./scripts/sync.sh push --dry-run
./scripts/sync.sh pull --dry-run
```

### Force Mode (Skip confirmations)
```bash
./scripts/sync.sh reset --force
```

### Individual Scripts
```bash
# Direct push script
./scripts/push-to-main.sh

# Direct pull script
./scripts/pull-from-main.sh
```

## 📁 File Structure

```
scripts/
├── sync.sh              # Main sync script (recommended)
├── push-to-main.sh      # Push operations
├── pull-from-main.sh    # Pull operations
├── supabase-utils.sh    # Utility functions
├── setup.sh             # Initial setup
├── README.md            # Detailed documentation
└── QUICK_REFERENCE.md   # This file

backups/supabase/        # Automatic backups
├── full_backup_*.sql    # Full database backups
├── local_backup_*.sql   # Local state backups
└── remote_data_*.sql    # Remote data exports
```

## ⚠️ Important Notes

1. **Always set password first:**
   ```bash
   export SUPABASE_DB_PASSWORD='your_password'
   ```

2. **Automatic backups:** All operations create backups automatically

3. **Git changes:** Local changes are stashed during pull operations

4. **Migration conflicts:** Scripts handle migration conflicts automatically

5. **Safety first:** Use `--dry-run` to test operations

## 🆘 Troubleshooting

### Common Issues
```bash
# Password not set
export SUPABASE_DB_PASSWORD='your_password'

# Permission denied
chmod +x scripts/*.sh

# Project not linked
cd vyaapari-nexus && supabase link --project-ref hycyhnjsldiokfkpqzoz

# Check status
./scripts/sync.sh status
```

### Recovery
```bash
# List backups
ls -la backups/supabase/

# Restore from backup
./scripts/sync.sh restore backups/supabase/latest_backup.sql

# Reset to remote
./scripts/sync.sh reset
```

## 📊 What Each Operation Does

### Push (`./scripts/sync.sh push`)
1. ✅ Creates backup of current state
2. ✅ Commits and pushes Git changes to main
3. ✅ Pushes Supabase migrations to remote
4. ✅ Exports local data and imports to remote
5. ✅ Updates project status

### Pull (`./scripts/sync.sh pull`)
1. ✅ Creates backup of local state
2. ✅ Stashes local Git changes
3. ✅ Pulls latest Git changes from main
4. ✅ Resets local Supabase to match remote
5. ✅ Pulls Supabase migrations from remote
6. ✅ Exports remote data and imports to local
7. ✅ Starts local Supabase
8. ✅ Optionally restores stashed changes

### Status (`./scripts/sync.sh status`)
1. ✅ Shows Git status (uncommitted changes)
2. ✅ Shows Supabase project status
3. ✅ Shows migration status
4. ✅ Shows database summary (size, tables, rows)

## 🎯 Best Practices

1. **Always backup before major operations**
2. **Test with `--dry-run` first**
3. **Keep password secure**
4. **Monitor status regularly**
5. **Use aliases for convenience**

---

**Need help?** Run `./scripts/sync.sh --help` for detailed usage information.
