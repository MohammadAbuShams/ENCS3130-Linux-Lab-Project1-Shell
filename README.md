# Linux Process Statistics Analyzer

## Overview
This project is a shell script designed to provide statistics about processes running on a Linux machine using the `top` command output. This script offers insights into CPU and memory usage, as well as network activity, by analyzing periodically captured data from `top`.

## Features
The script provides the following functionalities:
- **Read Data**: Input from a text file containing snapshots of the `top` command output.
- **Analyze CPU Usage**: Calculate and display the average, minimum, and maximum CPU usage.
- **Network Packets Received**: Analyze and display statistics on received network packets.
- **Network Packets Sent**: Provide details on sent network packets.
- **Top CPU-consuming Commands**: Display commands with the highest CPU usage.
- **Top Memory-consuming Commands**: Show commands with the highest and lowest memory usage based on user input.
- **Exit Safely**: Prompt for confirmation before exiting the script.

## Usage Instructions
1. **Start the Script**: Run the script from your terminal.
2. **Main Menu**: Navigate through the menu by entering the corresponding option:
    - `r` - Read data from a file.
    - `c` - Show CPU usage statistics.
    - `i` - Display statistics for received network packets.
    - `o` - Display statistics for sent network packets.
    - `u` - Find top CPU-consuming commands.
    - `a` - Find top memory-consuming commands.
    - `b` - Find the least memory-consuming commands.
    - `e` - Exit the script with confirmation.
3. **Input Requirements**: Depending on your choice, you may need to provide the filename for reading data or an integer `m` for listing top commands by resource usage.

## Contributors

- [Mohammad AbuShams](https://github.com/MohammadAbuShams)
- Abdalrahim Thiab
