# 0.1.0

## Added

- [x]  **Core hot reload functionality** with zero-downtime binary swapping
- [x]  **Intelligent file watching** system with cross-platform compatibility
- [x]  **YAML-based configuration** with `zeno.yml` support
- [x]  **Command-line interface** with multiple commands:
    - `zeno init` - Initialize new configuration file
    - `zeno run` - Start hot reloading (default command)
    - `zeno update` - Update CLI to latest version
    - `zeno --help` - Display usage information

- [x]  **Build lifecycle hooks** supporting pre and post-build commands
- [x]  **Flexible file filtering** with extension and directory controls
- [x]  **Comprehensive logging system** with configurable verbosity levels
- [x]  **Build error handling** with detailed error logging to `build-errors.log`
- [x]  **Automatic cleanup** of temporary files on exit
- [x]  **Configuration validation** with helpful error messages
- [x] **Debounced rebuilds** to prevent excessive builds during rapid file changes

