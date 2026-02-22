#!/bin/bash

# Цвета для интерфейса
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Проверка ffmpeg
command -v ffmpeg &> /dev/null || { echo -e "${RED}Ошибка: ffmpeg не установлен.${NC}"; exit 1; }

show_help() {
    echo -e "${WHITE}Использование:${NC} $0 [ВХОДНАЯ_ПАПКА] [ВЫХОДНОЙ_ФАЙЛ.opus]"
    echo ""
    echo "Опции:"
    echo "  -b, --bitrate    Битрейт для Opus (по умолчанию 96k)"
    echo "  -j, --jobs       Количество потоков (по умолчанию auto)"
    exit 0
}

# Значения по умолчанию
INPUT_DIR="."
OUTPUT_FILE="final_result.opus"
BITRATE="96k"
JOBS=$(nproc 2>/dev/null || echo 2)

# Разбор аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -b|--bitrate) BITRATE="$2"; shift 2 ;;
        -j|--jobs) JOBS="$2"; shift 2 ;;
        *) 
            if [ -d "$1" ]; then INPUT_DIR="$1"; elif [[ "$1" == *.opus ]]; then OUTPUT_FILE="$1"; fi
            shift ;;
    esac
done

# 1. Сбор файлов и умная сортировка (Natural Sort)
files=()
while IFS= read -r -d '' file; do
    files+=("$file")
done < <(find "$INPUT_DIR" -maxdepth 1 -type f -iname "*.mp3" -print0 | sort -zV)

total_files=${#files[@]}

if [ $total_files -eq 0 ]; then
    echo -e "${RED}Ошибка: MP3 файлы не найдены в $INPUT_DIR${NC}"
    exit 1
fi

# 2. Предварительный просмотр порядка файлов
clear
echo -e "${CYAN}════════════════ ПРОВЕРКА ПОРЯДКА ФАЙЛОВ ════════════════${NC}"
for i in "${!files[@]}"; do
    printf "${WHITE}%3d.${NC} %s\n" "$((i+1))" "$(basename "${files[$i]}")"
    # Показываем первые 15 и последние 5, если файлов слишком много
    if [ $total_files -gt 25 ] && [ $i -eq 14 ]; then
        echo "..."
        i=$((total_files - 6)) 
    fi
done
echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Всего файлов: $total_files${NC}"

# Подтверждение (Y по умолчанию)
read -p "Порядок верный? Начнем конвертацию? [Y/n]: " confirm
# Если нажали Enter (пустая строка) или Y/y, продолжаем
confirm=${confirm:-y} 
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Отмена."
    exit 0
fi

# 3. Подготовка временной папки
TEMP_OPUS_DIR=$(mktemp -d)
TEMP_OPUS_DIR_ABS=$(realpath "$TEMP_OPUS_DIR")

# 4. Конвертация (Параллельная обработка)
echo -e "\n${YELLOW}Конвертация в $JOBS потоках...${NC}"

export BITRATE TEMP_OPUS_DIR_ABS
convert_func() {
    local file="$1"
    local base=$(basename "$file" .mp3)
    ffmpeg -i "$file" -c:a libopus -b:a "$BITRATE" -vbr on -loglevel error -y "$TEMP_OPUS_DIR_ABS/$base.opus"
    echo -ne "${GREEN}#${NC}"
}
export -f convert_func

printf "%s\0" "${files[@]}" | xargs -0 -I {} -n 1 -P "$JOBS" bash -c 'convert_func "$@"' _ {}

# 5. Создание списка для склейки
LIST_FILE="$TEMP_OPUS_DIR_ABS/list.txt"
# Используем ls -v для сохранения естественного порядка во временной папке
ls -v "$TEMP_OPUS_DIR_ABS"/*.opus | awk '{ printf "file \047%s\047\n", $0 }' > "$LIST_FILE"

# 6. Финальная склейка
echo -e "\n\n${YELLOW}Объединение всех частей в $OUTPUT_FILE...${NC}"
ffmpeg -f concat -safe 0 -i "$LIST_FILE" -c copy -loglevel warning -y "$OUTPUT_FILE"

# Очистка
rm -rf "$TEMP_OPUS_DIR_ABS"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Готово! Файл сохранен: $OUTPUT_FILE${NC}"
else
    echo -e "${RED}❌ Ошибка во время склейки.${NC}"
fi
