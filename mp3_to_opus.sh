#!/bin/bash

# Определение языка системы [cite: 1]
detect_language() {
    local lang=${LANG:-en_US}
    case $lang in
        ru_RU*|ru_UA*|be_BY*|uk_UA*)
            echo "ru"
            ;;
        *)
            echo "en"
            ;;
    esac
}

LANGUAGE=${LANGUAGE:-$(detect_language)}
declare -A T

if [ "$LANGUAGE" = "ru" ]; then
    T[help_title]="ИСПОЛЬЗОВАНИЕ"
    T[help_description]="Пакетная конвертация MP3-файлов в формат Opus с сохранением качества."
    T[help_options]="ОПЦИИ"
    T[help_parameters]="ПАРАМЕТРЫ"
    T[help_examples]="ПРИМЕРЫ"
    T[help_opt]="Показать эту справку"
    T[bitrate_opt]="Установить битрейт (по умолчанию: 96k) [cite: 13]"
    T[jobs_opt]="Количество параллельных задач (по умолчанию: количество ядер CPU) [cite: 13, 25]"
    T[recursive_opt]="Рекурсивно обрабатывать подпапки [cite: 13]"
    T[force_opt]="Перезаписывать существующие файлы [cite: 13]"
    T[delete_opt]="Удалить исходный MP3 после успешной конвертации"
    T[input_dir_param]="входная_папка"
    T[output_dir_param]="выходная_папка"
    T[error_args]="Ошибка: неверное количество аргументов. [cite: 20]"
    T[error_input_dir]="Ошибка: входная папка не существует. [cite: 21]"
    T[error_output_dir]="Не удалось создать выходную папку [cite: 22]"
    T[error_ffmpeg]="Ошибка: ffmpeg не установлен. [cite: 23]"
    T[error_no_files]="MP3 файлы не найдены. [cite: 27]"
    T[error_space]="Внимание: недостаточно места на диске!"
    T[title]="КОНВЕРТАЦИЯ MP3 В OPUS"
    T[input_dir]="Входная папка"
    T[output_dir]="Выходная папка"
    T[bitrate]="Битрейт"
    T[threads]="Потоков"
    T[total_files]="Всего файлов"
    T[error_log]="Лог ошибок"
    T[starting]="Начинаем параллельную обработку..."
    T[complete]="КОНВЕРТАЦИЯ ЗАВЕРШЕНА"
    T[stats]="СТАТИСТИКА"
    T[success]="Успешно"
    T[skip]="Пропущено"
    T[error]="Ошибок"
    T[time]="Время"
    T[opus_files]="Opus файлов создано"
    T[done]="Готово"
    T[for_help]="Для справки используйте"
else
    T[help_title]="USAGE"
    T[help_description]="Batch convert MP3 files to Opus format[cite: 7, 8]."
    T[help_options]="OPTIONS"
    T[help_parameters]="PARAMETERS"
    T[help_examples]="EXAMPLES"
    T[help_opt]="Show this help [cite: 11]"
    T[bitrate_opt]="Set bitrate (default: 96k) [cite: 13]"
    T[jobs_opt]="Number of parallel jobs [cite: 13, 24]"
    T[recursive_opt]="Process subdirectories recursively [cite: 13, 17]"
    T[force_opt]="Overwrite existing files [cite: 13, 18]"
    T[delete_opt]="Delete source MP3 after successful conversion"
    T[input_dir_param]="input_directory"
    T[output_dir_param]="output_directory"
    T[error_args]="Error: invalid number of arguments. [cite: 20]"
    T[error_input_dir]="Error: input directory does not exist. [cite: 21]"
    T[error_output_dir]="Failed to create output directory [cite: 22]"
    T[error_ffmpeg]="Error: ffmpeg is not installed. [cite: 23]"
    T[error_no_files]="No MP3 files found. [cite: 27]"
    T[error_space]="Warning: not enough disk space!"
    T[title]="MP3 TO OPUS CONVERSION"
    T[input_dir]="Input directory"
    T[output_dir]="Output directory"
    T[bitrate]="Bitrate"
    T[threads]="Threads"
    T[total_files]="Total files"
    T[error_log]="Error log"
    T[starting]="Starting parallel processing..."
    T[complete]="CONVERSION COMPLETE"
    T[stats]="Statistics"
    T[success]="Success"
    T[skip]="Skipped"
    T[error]="Errors"
    T[time]="Time"
    T[opus_files]="Opus files created"
    T[done]="Done"
    T[for_help]="For help use"
fi

show_help() {
    cat << EOF
${T[help_title]}: $0 [${T[help_options]}] <${T[input_dir_param]}> <${T[output_dir_param]}>

${T[help_description]}

${T[help_options]}:
    -h, --help          ${T[help_opt]}
    -b <bitrate>        ${T[bitrate_opt]}
    -j <threads>        ${T[jobs_opt]}
    -r, --recursive     ${T[recursive_opt]}
    -f, --force         ${T[force_opt]}
    -d, --delete        ${T[delete_opt]}

${T[help_examples]}:
    $0 -j 4 -b 128k -r ~/Music/MP3 ~/Music/Opus
    $0 --delete ~/Music/MP3 ~/Music/Opus
EOF
}

# Цвета [cite: 13]
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Значения по умолчанию [cite: 13]
bitrate="96k"
jobs="auto"
recursive="false"
force="false"
delete_source="false"

# Обработка аргументов [cite: 14]
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -b) bitrate="$2"; shift 2 ;;
        -j) jobs="$2"; shift 2 ;;
        -r|--recursive) recursive="true"; shift ;;
        -f|--force) force="true"; shift ;;
        -d|--delete) delete_source="true"; shift ;;
        *) break ;;
    esac
done

if [ $# -ne 2 ]; then
    echo "${T[error_args]}"
    exit 1
fi

input_dir="$1"
output_dir="$2"

if [ ! -d "$input_dir" ]; then echo "${T[error_input_dir]}"; exit 1; fi
mkdir -p "$output_dir" || { echo "${T[error_output_dir]}"; exit 1; }
command -v ffmpeg &> /dev/null || { echo "${T[error_ffmpeg]}"; exit 1; }

# Определение потоков [cite: 24, 25]
if [ "$jobs" = "auto" ]; then
    jobs=$(nproc 2>/dev/null || echo 2)
fi

# Поиск файлов [cite: 26]
if [[ "$recursive" == "true" ]]; then
    mapfile -t files < <(find "$input_dir" -type f -iname "*.mp3" | sort)
else
    shopt -s nullglob nocaseglob
    files=("$input_dir"/*.mp3)
    shopt -u nullglob nocaseglob
fi

total_files=${#files[@]}
if [ $total_files -eq 0 ]; then echo "${T[error_no_files]}"; exit 0; fi

# Проверка места на диске
check_disk_space() {
    local source_size=$(du -sc "${files[@]}" | tail -n 1 | cut -f 1)
    local available_space=$(df -Pk "$output_dir" | tail -n 1 | awk '{print $4}')
    local estimated_needed=$((source_size / 3))

    if [ "$available_space" -lt "$estimated_needed" ]; then
        echo -e "${RED}${T[error_space]}${NC}"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
    fi
}
check_disk_space

# Логи и временные файлы [cite: 27]
timestamp=$(date +%Y%m%d_%H%M%S)
ERROR_LOG="$output_dir/conversion_errors_$timestamp.log"
RESULTS_FILE=$(mktemp)

# Функция конвертации [cite: 28-31]
convert_file() {
    local file="$1"
    local base=$(basename "$file")
    base="${base%.*}"
    
    local target_dir="$output_dir"
    if [[ "$recursive" == "true" ]]; then
        local rel_path="${file#$input_dir/}"
        local rel_dir=$(dirname "$rel_path")
        target_dir="$output_dir/$rel_dir"
    fi
    
    mkdir -p "$target_dir" 2>/dev/null
    local output_file="$target_dir/$base.opus"
    
    if [[ -f "$output_file" && "$force" != "true" ]]; then
        echo "SKIP:$file" >> "$RESULTS_FILE"
        return 0
    fi
    
    # Конвертация 
    if ffmpeg -i "$file" -c:a libopus -b:a "$bitrate" -vbr on -loglevel error -y "$output_file" 2>> "$ERROR_LOG"; then
        echo "SUCCESS:$file" >> "$RESULTS_FILE"
        echo -ne "${GREEN}✓${NC}"
        
        # Удаление оригинала, если флаг установлен
        if [[ "$delete_source" == "true" ]]; then
            rm -f "$file"
        fi
    else
        echo "ERROR:$file" >> "$RESULTS_FILE"
        echo -ne "${RED}✗${NC}"
    fi
}

export -f convert_file
export bitrate output_dir input_dir recursive force delete_source ERROR_LOG RESULTS_FILE T GREEN RED NC

# Интерфейс
clear
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}              ${T[title]}${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}${T[threads]}:${NC} $jobs"
echo -e "${WHITE}${T[total_files]}:${NC} $total_files"
[[ "$delete_source" == "true" ]] && echo -e "${RED}⚠ ${T[delete_opt]} ACTIVE${NC}"
echo -e "${YELLOW}${T[starting]}${NC}\n"

start_time=$(date +%s)

# Параллельный запуск через xargs
printf "%s\n" "${files[@]}" | xargs -I {} -d '\n' -n 1 -P "$jobs" bash -c 'convert_file "$@"' _ {}

# Итоги
success_count=$(grep -c "SUCCESS:" "$RESULTS_FILE" || echo 0)
skip_count=$(grep -c "SKIP:" "$RESULTS_FILE" || echo 0)
error_count=$(grep -c "ERROR:" "$RESULTS_FILE" || echo 0)
actual_files=$(find "$output_dir" -name "*.opus" -type f 2>/dev/null | wc -l)
end_time=$(date +%s)
total_time="$((end_time - start_time))s"

echo -e "\n\n${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}              ${T[complete]}${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "   ${GREEN}✅ ${T[success]}:${NC}  $success_count"
echo -e "   ${YELLOW}⏭️  ${T[skip]}:${NC}     $skip_count"
echo -e "   ${RED}❌ ${T[error]}:${NC}    $error_count"
echo -e "   ${WHITE}⏱️  ${T[time]}:${NC}     $total_time"
echo -e "   ${WHITE}📁 ${T[opus_files]}:${NC} $actual_files"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"

rm -f "$RESULTS_FILE"

# Звук [cite: 40]
if command -v paplay &> /dev/null && [ -f "/usr/share/sounds/freedesktop/stereo/complete.oga" ]; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
fi
