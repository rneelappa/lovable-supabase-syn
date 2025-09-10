# Lovable Supabase Sync - Deployment Guide

## 🚀 Quick Start

### 1. Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it: `lovable-supabase-sync`
3. Make it public
4. Don't initialize with README (we already have one)

### 2. Push to GitHub

```bash
cd /Users/rajkumarneelappa/Documents/lovable-supabase-sync

# Add the remote (replace with your actual GitHub URL)
git remote add origin https://github.com/rneelappa/lovable-supabase-sync.git

# Push to GitHub
git push -u origin main
```

### 3. Verify Deployment

Visit: https://github.com/rneelappa/lovable-supabase-sync

## 📦 Installation Methods

### Method 1: Direct Clone

```bash
git clone https://github.com/rneelappa/lovable-supabase-sync.git
cd lovable-supabase-sync
./install.sh --project-dir /path/to/your/project
```

### Method 2: Download and Install

```bash
# Download the latest release
curl -L https://github.com/rneelappa/lovable-supabase-sync/archive/main.zip -o lovable-supabase-sync.zip
unzip lovable-supabase-sync.zip
cd lovable-supabase-sync-main
./install.sh --project-dir /path/to/your/project
```

### Method 3: Copy Scripts

```bash
# Copy the tool to your project
cp -r lovable-supabase-sync/.supabase-sync /path/to/your/project/
cd /path/to/your/project
chmod +x .supabase-sync/scripts/*.sh
```

## 🔧 Configuration

### Basic Configuration

1. **Copy example config:**
   ```bash
   cp .supabase-sync/config/project-config.example.sh .supabase-sync/config/project-config.sh
   ```

2. **Edit configuration:**
   ```bash
   nano .supabase-sync/config/project-config.sh
   ```

3. **Set your values:**
   ```bash
   GIT_REMOTE_URL="https://github.com/your-username/your-repo.git"
   SUPABASE_PROJECT_REF="your-supabase-project-ref"
   SUPABASE_DB_PASSWORD="your-supabase-password"
   ```

### Advanced Configuration

Use the example configurations for different project types:

- **React Project:** `examples/react-project.sh`
- **Next.js Project:** `examples/nextjs-project.sh`

## 🎯 Usage

### Basic Commands

```bash
# Setup
./supabase-sync.sh setup
./supabase-sync.sh config
./supabase-sync.sh validate

# Sync operations
./supabase-sync.sh push
./supabase-sync.sh pull
./supabase-sync.sh status

# Backup and restore
./supabase-sync.sh backup
./supabase-sync.sh restore backup.sql
```

### Convenience Aliases

```bash
# Source aliases
source .supabase-sync/aliases.sh

# Use aliases
supabase-push
supabase-pull
supabase-status
```

## 📊 Project Structure

```
your-project/
├── .supabase-sync/
│   ├── scripts/                    # All sync scripts
│   ├── config/                     # Configuration files
│   ├── backups/                    # Automatic backups
│   └── logs/                       # Log files
├── supabase/                       # Your Supabase project
└── supabase-sync.sh               # Convenience script
```

## 🛡️ Features

### Core Features
- ✅ **Git + Supabase Sync** - Automated synchronization
- ✅ **Conflict Resolution** - Smart handling of merge conflicts
- ✅ **Docker Management** - Automatic container management
- ✅ **Health Monitoring** - Comprehensive service checks
- ✅ **Backup & Restore** - Automatic backups with restore

### Advanced Features
- ✅ **Port Conflict Resolution** - Automatic port management
- ✅ **Migration Management** - Safe migration deployment
- ✅ **Data Synchronization** - Bidirectional data sync
- ✅ **Error Recovery** - Automatic cleanup and recovery
- ✅ **Configuration Management** - Flexible project configuration

## 🔍 Troubleshooting

### Common Issues

1. **Repository not found:**
   - Create the GitHub repository first
   - Check the repository URL

2. **Permission denied:**
   - Make scripts executable: `chmod +x .supabase-sync/scripts/*.sh`

3. **Configuration errors:**
   - Run: `./supabase-sync.sh validate`
   - Check your configuration file

4. **Docker issues:**
   - Ensure Docker is running
   - The tool will try to start Docker automatically

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

## 📚 Documentation

- **Main README:** [README.md](README.md)
- **Script Documentation:** [scripts/README.md](scripts/README.md)
- **Quick Reference:** [scripts/QUICK_REFERENCE.md](scripts/QUICK_REFERENCE.md)
- **Examples:** [examples/](examples/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **GitHub Issues:** Report issues on GitHub
- **GitHub Discussions:** Use Discussions for questions
- **Documentation:** Check the README and inline help

---

**Ready to sync! 🚀**
