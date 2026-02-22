# Audio Tools & File Manager 🎧

A collection of professional Bash scripts for audio processing (MP3, Opus) and file management on Ubuntu 24.04.

## Tools Overview

1.  **mp3_to_opus.sh** — Multithreaded batch converter from MP3 to Opus format.
2.  **create_file_list.sh** — Advanced file list generator for ffmpeg concat and general use.
3.  **opus_concat.sh** — Tool for merging multiple Opus files into one.

---

## Detailed Script Documentation

### 1. mp3_to_opus.sh
Automates conversion with system language detection (EN/RU) and parallel processing.

* **Usage:** `./mp3_to_opus.sh [OPTIONS] <input_directory> <output_directory>`
* **Options:**
    * `-b <bitrate>` — Set output bitrate (default: `96k`).
    * `-j <threads>` — Number of parallel jobs (default: CPU core count).
    * `-r, --recursive` — Process subdirectories recursively.
    * `-f, --force` — Overwrite existing files in the output folder.
    * `-d, --delete` — Delete source MP3 files after successful conversion.
* **Key Features:** Includes disk space checks, error logging, and automatic subdirectory creation in the output path.

---

### 2. create_file_list.sh
Creates a formatted list of files specifically for the `ffmpeg` concat demuxer.

* **Usage:** `./create_file_list.sh [OPTIONS] EXTENSION`
* **Parameters:**
    * `EXTENSION` — File extension to search for (e.g., `mp3`). If empty, finds files without extensions.
* **Options:**
    * `-s, --sort <TYPE>` — Sort type: `auto` (smart), `name` (alphabetical), `natural` (numeric-aware), `time` (modification date), `size`, or `none`.
    * `-r, --reverse` — Reverse the sort order.
    * `-o <FILE>` — Output filename (default: `files.txt`).
    * `-d <DIR>` — Search directory (default: current directory).
* **Key Features:** Uses absolute paths and handles special characters in filenames safely for ffmpeg.

---

### 3. opus_concat.sh
Merges Opus files into a single output file with optional re-encoding.

* **Usage:** `./opus_concat.sh [OPTIONS] [list_file.txt] [output_file.opus]`
* **Modes:**
    * `-c, --copy` — (Default) Stream copy mode. Instant merging without quality loss.
    * `-r, --reencode` — Re-encode to a standard bitrate (useful for mixing different sources).
* **Parameters:**
    * `[list_file.txt]` — A text file containing a list of files to merge.
    * `[output_file.opus]` — Name of the resulting file (default: `result.opus`).
* **Key Features:** If no list is provided, it automatically gathers and sorts all `.opus` files in the current directory using version-sort (`ls -v`).

---

## Requirements

Ensure `ffmpeg` is installed on your system:
```bash
sudo apt update
sudo apt install ffmpeg
```

##Installation & Setup

    Clone the repository.

    Grant execution permissions to the scripts:
   ``` Bash

    chmod +x mp3_to_opus.sh create_file_list.sh opus_concat.sh
   ```

    Run the scripts directly from the terminal.
---
Developed for efficient audio collection (audiobooks) management in the Linux console.
Developed for efficient audio collection management in the Linux console.
