#!/bin/bash
# Update package lists
sudo apt update

# Install SQLite command-line tool
sudo apt install sqlite3

# (Optional) Install development headers if you want to compile software against SQLite
sudo apt install libsqlite3-dev

# Verify installation
sqlite3 --version