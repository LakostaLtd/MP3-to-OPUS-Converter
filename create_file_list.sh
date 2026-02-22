#!/bin/bash

# Функция для отображения справки
show_help() {
    echo "Использование: $0 [ОПЦИИ] РАСШИРЕНИЕ"
    echo "Создает список файлов для ffmpeg concat из текущего каталога"
    echo ""
    echo "Опции сортировки:"
    echo "  -s, --sort TYPE     Тип сортировки (auto, name, natural, time, size, none)"
    echo "  -r, --reverse       Обратный порядок"
    echo "  -o FILE             Имя выходного файла (по умолчанию: files.txt)"
    echo "  -d DIR              Каталог для поиска (по умолчанию: текущий)"
    exit 0
}

output_file="files.txt"
search_dir="."
extension=""
sort_type="auto"
reverse=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -o) output_file="$2"; shift 2 ;;
        -d) search_dir="$2"; shift 2 ;;
        -s|--sort) sort_type="$2"; shift 2 ;;
        -r|--reverse) reverse="-r"; shift ;;
        *) extension="$1"; shift ;;
    esac
done

if [[ -z "$extension" && "$extension" != "" ]]; then
    echo "Ошибка: не указано расширение"
    exit 1
fi

# Проверка каталога и получение абсолютного пути к нему
if [[ ! -d "$search_dir" ]]; then
    echo "Ошибка: каталог '$search_dir' не существует"
    exit 1
fi
search_dir_abs=$(realpath "$search_dir")

# Путь к выходному файлу (чтобы не зависеть от cd)
output_path=$(realpath -m "$output_file")

# Переходим в каталог поиска
cd "$search_dir_abs" || exit 1

# Проверка sort -V
SORT_CMD="sort"
if ! sort -V </dev/null &>/dev/null; then
    command -v gsort &>/dev/null && SORT_CMD="gsort"
fi

temp_files=$(mktemp)
ext_clean="${extension#.}"

# --- Поиск файлов ---
# Используем -maxdepth 1, как в оригинале
if [[ -z "$ext_clean" ]]; then
    find . -maxdepth 1 -type f ! -name "*.*" -print0 > "$temp_files.raw"
else
    find . -maxdepth 1 -type f -iname "*.$ext_clean" -print0 > "$temp_files.raw"
fi

if [[ ! -s "$temp_files.raw" ]]; then
    echo "Файлы не найдены."
    rm -f "$temp_files"*
    exit 0
fi

# Преобразуем сразу в абсолютные пути БЕЗ лишних символов
xargs -0 realpath > "$temp_files" < "$temp_files.raw"

# Определение сортировки
detect_sort_type() {
    head -n 20 "$1" | grep -q '[0-9]' && echo "natural" || echo "name"
}

[[ "$sort_type" == "auto" ]] && real_sort_type=$(detect_sort_type "$temp_files") || real_sort_type="$sort_type"

echo "Сортировка: $real_sort_type"

# --- Сортировка ---
case $real_sort_type in
    natural) $SORT_CMD -V $reverse "$temp_files" > "$temp_files.sorted" ;;
    time)    find . -maxdepth 1 -type f ${ext_clean:+-iname "*.$ext_clean"} -printf "%T@ %p\n" | sort -n $reverse | cut -d' ' -f2- | xargs realpath > "$temp_files.sorted" ;;
    size)    find . -maxdepth 1 -type f ${ext_clean:+-iname "*.$ext_clean"} -printf "%s %p\n" | sort -n $reverse | cut -d' ' -f2- | xargs realpath > "$temp_files.sorted" ;;
    none)    cp "$temp_files" "$temp_files.sorted" ;;
    *)       sort $reverse "$temp_files" > "$temp_files.sorted" ;;
esac

# --- Финальный вывод ---
# Важно: используем одинарные кавычки аккуратно через awk
awk '{ printf "file \047%s\047\n", $0 }' "$temp_files.sorted" > "$output_path"

found_files=$(wc -l < "$output_path")
echo "Найдено файлов: $found_files"
echo "Файл списка: $output_path"

if [[ $found_files -gt 0 ]]; then
    echo -e "\nПревью:"
    head -n 3 "$output_path"
fi

rm -f "$temp_files"*
