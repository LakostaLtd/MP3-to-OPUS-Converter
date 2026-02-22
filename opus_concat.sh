#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    echo "Использование: $0 [ОПЦИИ] [файл_списка.txt] [выходной_файл.opus]"
    echo ""
    echo "Если параметры не указаны:"
    echo "  1. Скрипт ищет все .opus файлы в текущей папке."
    echo "  2. Создает файл по умолчанию: result.opus"
    echo ""
    echo "Опции:"
    echo "  -c, --copy      Без перекодировки (мгновенно, без потери качества)"
    echo "  -r, --reencode  С перекодировкой (если файлы имеют разный битрейт)"
    echo "  -h, --help      Показать эту справку"
    exit 0
}

mode="copy"
input_list=""
output_file="result.opus" # Имя по умолчанию

# Разбор параметров
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -c|--copy) mode="copy"; shift ;;
        -r|--reencode) mode="reencode"; shift ;;
        *) 
            if [[ -z "$input_list" && "$1" == *.txt ]]; then
                input_list="$1"
            else
                # Если параметр не .txt, значит это имя выходного файла
                output_file="$1"
                # Добавляем расширение, если пользователь его забыл
                [[ "$output_file" != *.opus ]] && output_file="${output_file}.opus"
            fi
            shift 
            ;;
    esac
done

# Проверка ffmpeg
command -v ffmpeg &> /dev/null || { echo -e "${RED}Ошибка: ffmpeg не установлен.${NC}"; exit 1; }

temp_created=false
if [[ -z "$input_list" ]]; then
    echo -e "${YELLOW}Файл списка не указан. Собираю файлы автоматически...${NC}"
    input_list=$(mktemp)
    temp_created=true
    
    # Сортировка:
    # ls -v (версионная сортировка) идеально справляется с:
    # 1. 01.opus, 02.opus, 10.opus
    # 2. name01.opus, name10.opus
    # 3. Файлы без цифр (просто алфавитный порядок)
    ls -v *.opus 2>/dev/null | grep -v "^$output_file$" | awk '{ printf "file \047%s/%s\047\n", ENVIRON["PWD"], $0 }' > "$input_list"
    
    if [[ ! -s "$input_list" ]]; then
        echo -e "${RED}Ошибка: В текущей папке не найдено подходящих .opus файлов.${NC}"
        rm -f "$input_list"
        exit 1
    fi
fi

echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}             ОБЪЕДИНЕНИЕ OPUS ФАЙЛОВ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "Выход:  ${WHITE}$output_file${NC}"
echo -e "Режим:  ${WHITE}$mode${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────${NC}"

# Команда объединения
if [ "$mode" == "copy" ]; then
    ffmpeg -f concat -safe 0 -i "$input_list" -c copy -loglevel warning -y "$output_file"
else
    ffmpeg -f concat -safe 0 -i "$input_list" -c:a libopus -b:a 96k -vbr on -loglevel warning -y "$output_file"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Готово! Файл сохранен как: $output_file${NC}"
else
    echo -e "${RED}❌ Произошла ошибка при работе ffmpeg.${NC}"
fi

# Удаление временного файла
[[ "$temp_created" == "true" ]] && rm -f "$input_list"
