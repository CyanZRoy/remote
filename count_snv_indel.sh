#!/usr/bin/env bash
set -euo pipefail

# 线程数：默认用 CPU 核心数；也可手动：THREADS=8 ./count_snv_indel.sh
THREADS="${THREADS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
OUT="${OUT:-snv_indel_counts.tsv}"

shopt -s nullglob

# 需要统计的文件（当前目录）
files=( *.vcf *.vcf.gz )

if (( ${#files[@]} == 0 )); then
  echo "ERROR: 当前目录未找到 *.vcf 或 *.vcf.gz" >&2
  exit 1
fi

# 输出表头
printf "File\tSNV\tINDEL\tOTHER\tTOTAL\n" > "$OUT"

# 计数函数：对单个 VCF 计数并输出一行
count_one() {
  local f="$1"
  local reader
  if [[ "$f" == *.gz ]]; then
    reader="gzip -cd"
  else
    reader="cat"
  fi

  # 统计逻辑在 awk 里做：跳过 header；处理多等位 ALT（含逗号）先归为 OTHER
  # 注意：这里按“记录行数”统计（不是按等位基因拆分计数）
  local line
  line="$(
    $reader "$f" | awk -F'\t' '
      BEGIN{snv=0; indel=0; other=0; total=0}
      /^#/ {next}
      {
        ref=$4; alt=$5;
        total++;
        # 多等位（含逗号）先算 OTHER，避免误分
        if (alt ~ /,/) {other++; next}

        # 只处理常规碱基（包含 N）
        if (ref !~ /^[ACGTN]+$/ || alt !~ /^[ACGTN]+$/) {other++; next}

        if (length(ref)==1 && length(alt)==1) {snv++}
        else if (length(ref)!=length(alt)) {indel++}
        else {other++}
      }
      END{printf "%d\t%d\t%d\t%d", snv, indel, other, total}
    '
  )"

  printf "%s\t%s\n" "$f" "$line"
}

export -f count_one

# 多线程：优先用 GNU parallel；没有就用 xargs -P
if command -v parallel >/dev/null 2>&1; then
  parallel -j "$THREADS" --no-notice count_one ::: "${files[@]}" >> "$OUT"
else
  # xargs 版本
  printf "%s\0" "${files[@]}" \
    | xargs -0 -n 1 -P "$THREADS" bash -c 'count_one "$0"' \
    >> "$OUT"
fi

# 按文件名排序一下（可选）
{ head -n 1 "$OUT"; tail -n +2 "$OUT" | sort -k1,1; } > "${OUT}.tmp" && mv "${OUT}.tmp" "$OUT"

echo "Done. 输出：$OUT"

