# Audio Tools & Master Manager 🎧

A collection of professional Bash scripts for audio processing and automation on Ubuntu 24.04. This project now features a "Master Manager" that automates the entire workflow from raw MP3s to a single merged Opus file.

## Key Tools

### 1. audio_manager.sh (The "All-in-One" Tool)
This is the main script that combines the logic of conversion, listing, and concatenation into a single pipeline.

* **Workflow:**
    1.  Scans the input directory for MP3 files.
    2.  Converts them to Opus format using parallel processing (multi-threading).
    3.  Automatically generates a temporary sort-order list.
    4.  Merges all parts into one final `.opus` file.
    5.  Cleans up all intermediate files automatically.

* **Usage:**
    ```bash
    ./audio_manager.sh [OPTIONS] <input_directory> <output_file.opus>
    ```
* **Options:**
    * `-b, --bitrate` — Set audio quality (e.g., `128k`). Default is `96k`.
    * `-j, --jobs` — Number of CPU threads to use for conversion.
    * `-h, --help` — Display help information.

---

## Individual Component Scripts

If you need more granular control, you can still use the standalone scripts:

### 2. mp3_to_opus.sh
Batch converter with bilingual support (EN/RU).
* **Features:** Preserves directory structures and checks for available disk space before starting.
* **Usage:** `./mp3_to_opus.sh [OPTIONS] <input_dir> <output_dir>`

### 3. create_file_list.sh
Generates formatted file lists with advanced sorting capabilities.
* **Sort Types:** Supports `natural` (numeric), `time`, `size`, and `name` sorting.
* **Usage:** `./create_file_list.sh -s natural -o my_list.txt mp3`

### 4. opus_concat.sh
Merges existing Opus files either by re-encoding or via instant "stream copy" (no quality loss).
* **Usage:** `./opus_concat.sh --copy [list.txt] [result.opus]`

---

## Technical Requirements

All scripts require `ffmpeg` to be installed:
```bash
sudo apt update && sudo apt install ffmpeg
```

Installation

 Clone this repository to your Ubuntu machine.

 Make all scripts executable:
    ```bash

        chmod +x *.sh

   ``` 
