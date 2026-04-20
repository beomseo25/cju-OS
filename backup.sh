#!/bin/bash

# ==========================================
# 🎨 Color Codes (터미널 글자 색상 세팅)
# ==========================================
GREEN='\033[1;32m'
BLUE='\033[1;34m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color (원래 색상으로 복귀)

# ==========================================
# ⚙️ Configuration (변수 세팅)
# ==========================================
TARGET_DIR=${1:-"."}
DAYS=${2:-30}
BACKUP_DIR="$HOME/backup_dir"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

# 🖥️ 시작 화면 UI 출력
echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}       [ Backup & Cleanup Automation Script ]      ${NC}"
echo -e "${BLUE}===================================================${NC}"
echo -e "${YELLOW} Target Directory : ${NC} ${TARGET_DIR}"
echo -e "${YELLOW} Criteria (Days)  : ${NC} Older than ${DAYS} days"
echo -e "${YELLOW} Backup Location  : ${NC} ${BACKUP_DIR}"
echo -e "${BLUE}---------------------------------------------------${NC}"

# 1. 백업 디렉토리가 없으면 생성
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo -e "${GREEN}[+] Created new backup directory: ${BACKUP_DIR}${NC}"
fi

# 2. 대상 파일 개수 세기 (파일이 없으면 깔끔하게 종료)
FILE_COUNT=$(find "$TARGET_DIR" -type f -mtime +"$DAYS" | wc -l)

if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${GREEN}[✔] No files older than ${DAYS} days found. System is clean!${NC}"
    echo -e "${BLUE}===================================================${NC}"
    exit 0
fi

echo -e "${GREEN}[✔] Found ${FILE_COUNT} file(s) to process.${NC}\n"

# ==========================================
# 📦 STEP 1: 백업(압축) 진행
# ==========================================
echo -e "${YELLOW}>>> [STEP 1] Archiving Files... <<<${NC}"

# tar 명령어의 -v 옵션을 이용해 압축되는 파일 목록을 화면에 예쁘게 출력
find "$TARGET_DIR" -type f -mtime +"$DAYS" -print0 | tar -czvf "$ARCHIVE_PATH" --null -T - | awk '{print "    [Archived] "$0}'

# 압축이 에러 없이 완벽하게 성공했는지 확인 (안전장치)
if [ ${PIPESTATUS[1]} -eq 0 ]; then
    echo -e "\n${RED}>>> [STEP 2] Deleting Original Files... <<<${NC}"

    # ==========================================
    # 🗑️ STEP 2: 원본 파일 삭제
    # ==========================================
    find "$TARGET_DIR" -type f -mtime +"$DAYS" -print | while read -r file; do
        rm -f "$file"
        echo -e "    ${RED}[Deleted]${NC} $file"
    done

    # 🚀 최종 결과 요약 출력
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${GREEN}[✔] SUCCESS! Backup and cleanup completed safely.${NC}"
    echo -e "${YELLOW}📁 Saved Archive : ${NC}${ARCHIVE_PATH}"
    echo -e "${BLUE}===================================================${NC}"
else
    # 압축 중 문제가 생겼다면 삭제를 중단하여 원본 파일을 보호!
    echo -e "\n${RED}[✖] ERROR: Archiving failed! Original files were NOT deleted to keep them safe.${NC}"
    exit 1
fi
