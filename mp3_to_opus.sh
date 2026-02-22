#!/bin/bash

# Определение языка системы
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

# Устанавливаем язык (можно переопределить переменной LANGUAGE)
LANGUAGE=${LANGUAGE:-$(detect_language)}

# Массивы переводов
declare -A T

if [ "$LANGUAGE" = "ru" ]; then
    # Русский язык
    T[help_title]="ИСПОЛЬЗОВАНИЕ"
    T[help_description]="Пакетная конвертация MP3-файлов в формат Opus с сохранением качества."
    T[help_options]="ОПЦИИ"
    T[help_parameters]="ПАРАМЕТРЫ"
    T[help_examples]="ПРИМЕРЫ"
    T[help_opt]="Показать эту справку"
    T[bitrate_opt]="Установить битрейт (по умолчанию: 96k)"
    T[jobs_opt]="Количество параллельных задач (по умолчанию: количество ядер CPU)"
    T[recursive_opt]="Рекурсивно обрабатывать подпапки"
    T[force_opt]="Перезаписывать существующие файлы"
    T[input_dir_param]="входная_папка"
    T[output_dir_param]="выходная_папка"
    T[example1]="Базовая конвертация"
    T[example2]="С битрейтом 128k и рекурсивно"
    T[example3]="С 4 потоками"
    T[error_args]="Ошибка: неверное количество аргументов."
    T[error_input_dir]="Ошибка: входная папка не существует."
    T[error_output_dir]="Не удалось создать выходную папку"
    T[error_ffmpeg]="Ошибка: ffmpeg не установлен."
    T[error_no_files]="MP3 файлы не найдены."
    T[title]="КОНВЕРТАЦИЯ MP3 В OPUS"
    T[input_dir]="Входная папка"
    T[output_dir]="Выходная папка"
    T[bitrate]="Битрейт"
    T[threads]="Потоков"
    T[total_files]="Всего файлов"
    T[error_log]="Лог ошибок"
    T[starting]="Начинаем обработку..."
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
    # Английский язык (по умолчанию)
    T[help_title]="USAGE"
    T[help_description]="Batch convert MP3 files to Opus format with quality preservation."
    T[help_options]="OPTIONS"
    T[help_parameters]="PARAMETERS"
    T[help_examples]="EXAMPLES"
    T[help_opt]="Show this help"
    T[bitrate_opt]="Set bitrate (default: 96k)"
    T[jobs_opt]="Number of parallel jobs (default: CPU cores)"
    T[recursive_opt]="Process subdirectories recursively"
    T[force_opt]="Overwrite existing files"
    T[input_dir_param]="input_directory"
    T[output_dir_param]="output_directory"
    T[example1]="Basic conversion"
    T[example2]="With 128k bitrate and recursive"
    T[example3]="With 4 threads"
    T[error_args]="Error: invalid number of arguments."
    T[error_input_dir]="Error: input directory does not exist."
    T[error_output_dir]="Failed to create output directory"
    T[error_ffmpeg]="Error: ffmpeg is not installed."
    T[error_no_files]="No MP3 files found."
    T[title]="MP3 TO OPUS CONVERSION"
    T[input_dir]="Input directory"
    T[output_dir]="Output directory"
    T[bitrate]="Bitrate"
    T[threads]="Threads"
    T[total_files]="Total files"
    T[error_log]="Error log"
    T[starting]="Starting processing..."
    T[complete]="CONVERSION COMPLETE"
    T[stats]="STATISTICS"
    T[success]="Success"
    T[skip]="Skipped"
    T[error]="Errors"
    T[time]="Time"
    T[opus_files]="Opus files created"
    T[done]="Done"
    T[for_help]="For help use"
fi

# Функция вывода справки (теперь с переводами)
show_help() {
    cat << EOF
${T[help_title]}: $0 [${T[help_options]}] <${T[input_dir_param]}> <${T[output_dir_param]}>

${T[help_description]}

${T[help_options]}:
    -h, --help          ${T[help_opt]}
    -b <${T[bitrate],,}>        ${T[bitrate_opt]}
                        ${T[example1]}: 64k, 96k, 128k, 160k
    -j <${T[threads],,}>          ${T[jobs_opt]}
    -r, --recursive     ${T[recursive_opt]}
    -f, --force         ${T[force_opt]}

${T[help_parameters]}:
    ${T[input_dir_param]}       ${T[input_dir]}
    ${T[output_dir_param]}      ${T[output_dir]}

${T[help_examples]}:
    $0 ~/Music/MP3 ~/Music/Opus                 # ${T[example1]}
    $0 -b 128k -r ~/Music/MP3 ~/Music/Opus      # ${T[example2]}
    $0 -j 4 -b 96k ~/Music/MP3 ~/Music/Opus     # ${T[example3]}
    $0 -h                                        # ${T[for_help]}

EOF
}

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Значения по умолчанию
bitrate="96k"
jobs="auto"
recursive="false"
force="false"

# Обработка аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -b)
            bitrate="$2"
            shift 2
            ;;
        -j)
            jobs="$2"
            shift 2
            ;;
        -r|--recursive)
            recursive="true"
            shift
            ;;
        -f|--force)
            force="true"
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ $# -ne 2 ]; then
    echo "${T[error_args]}"
    echo "${T[for_help]}: $0 --help"
    exit 1
fi

input_dir="$1"
output_dir="$2"

if [ ! -d "$input_dir" ]; then
    echo "${T[error_input_dir]}"
    exit 1
fi

mkdir -p "$output_dir" || { 
    echo "${T[error_output_dir]} '$output_dir'"
    exit 1
}

if ! command -v ffmpeg &> /dev/null; then
    echo "${T[error_ffmpeg]}"
    exit 1
fi

# Определяем количество потоков
if [ "$jobs" = "auto" ]; then
    if command -v nproc &> /dev/null; then
        jobs=$(nproc)
    else
        jobs=2
    fi
fi

# Собираем файлы
if [[ "$recursive" == "true" ]]; then
    mapfile -t files < <(find "$input_dir" -type f -iname "*.mp3" | sort)
else
    shopt -s nullglob nocaseglob
    files=("$input_dir"/*.mp3)
    shopt -u nullglob nocaseglob
fi

total_files=${#files[@]}

if [ $total_files -eq 0 ]; then
    echo "${T[error_no_files]}"
    exit 0
fi

# Лог ошибок
timestamp=$(date +%Y%m%d_%H%M%S)
ERROR_LOG="$output_dir/conversion_errors_$timestamp.log"
echo "${T[error_log]} $(date)" > "$ERROR_LOG"
echo "${T[bitrate]}: $bitrate" >> "$ERROR_LOG"
echo "----------------------------------------" >> "$ERROR_LOG"

# Вывод информации
clear
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}              ${T[title]}${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}${T[input_dir]}:${NC}  $input_dir"
echo -e "${WHITE}${T[output_dir]}:${NC} $output_dir"
echo -e "${WHITE}${T[bitrate]}:${NC}       $bitrate"
echo -e "${WHITE}${T[threads]}:${NC}       $jobs"
echo -e "${WHITE}${T[total_files]}:${NC}  $total_files"
echo -e "${WHITE}${T[error_log]}:${NC} $ERROR_LOG"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo ""

# Временный файл для результатов
RESULTS_FILE=$(mktemp)
touch "$RESULTS_FILE"

# Начальное время
start_time=$(date +%s)

# Функция конвертации
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
        return 2
    fi
    
    if ffmpeg -i "$file" -c:a libopus -b:a "$bitrate" -vbr on -loglevel error "$output_file" 2>> "$ERROR_LOG"; then
        echo "SUCCESS:$file" >> "$RESULTS_FILE"
        return 0
    else
        echo "ERROR:$file" >> "$RESULTS_FILE"
        return 1
    fi
}

# Функция отображения прогресса
show_progress() {
    local current=$1
    local total=$2
    local success=$3
    local skip=$4
    local error=$5
    local filename=$6
    
    local percent=$((current * 100 / total))
    local bar_size=30
    local filled=$((percent * bar_size / 100))
    
    printf "\r\033[K["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=filled; i<bar_size; i++)); do printf "░"; done
    printf "] %3d%%" $percent
    printf " ${GREEN}✓%d${NC} ${YELLOW}⏭️%d${NC} ${RED}✗%d${NC}" $success $skip $error
    printf " ${BLUE}%d/%d${NC}" $current $total
    printf " ${WHITE}|${NC} %s" "${filename:0:30}"
}

echo -e "${YELLOW}${T[starting]}${NC}\n"

success_count=0
skip_count=0
error_count=0

for i in "${!files[@]}"; do
    current=$((i + 1))
    file="${files[$i]}"
    base=$(basename "$file")
    base="${base%.*}"
    
    convert_file "$file"
    result=$?
    
    case $result in
        0) ((success_count++)) ;;
        2) ((skip_count++)) ;;
        *) ((error_count++)) ;;
    esac
    
    show_progress $current $total_files $success_count $skip_count $error_count "$base"
done

echo -e "\n"

# Подсчитываем реальные файлы в выходной папке
actual_files=$(find "$output_dir" -name "*.opus" -type f 2>/dev/null | wc -l)

# Итоговое время
end_time=$(date +%s)
total_seconds=$((end_time - start_time))
if [ $total_seconds -lt 60 ]; then
    total_time="${total_seconds}с"
else
    minutes=$((total_seconds / 60))
    seconds=$((total_seconds % 60))
    total_time="${minutes}м ${seconds}с"
fi

# Удаляем временный файл
rm -f "$RESULTS_FILE"

# Вывод статистики
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}              ${T[complete]}${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}📊 ${T[stats]}:${NC}"
echo -e "   ${WHITE}📂 ${T[total_files]}:${NC}    $total_files"
echo -e "   ${GREEN}✅ ${T[success]}:${NC}        $success_count"
echo -e "   ${YELLOW}⏭️  ${T[skip]}:${NC}          $skip_count"
echo -e "   ${RED}❌ ${T[error]}:${NC}         $error_count"
echo -e "   ${WHITE}⏱️  ${T[time]}:${NC}          $total_time"
echo -e "   ${WHITE}📁 ${T[opus_files]}:${NC}    $actual_files"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}📝 ${T[error_log]}:${NC} $ERROR_LOG"
echo -e "${GREEN}✅ ${T[done]}!${NC}"

# Звуковое уведомление
if command -v paplay &> /dev/null && [ -f "/usr/share/sounds/freedesktop/stereo/complete.oga" ]; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
fi
