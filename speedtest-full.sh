#!/bin/bash

# Cores ANSI
ROXO='\033[1;35m'
AZUL='\033[1;34m'
VERDE='\033[1;32m'
CIANO='\033[1;36m'
VERMELHO='\033[1;31m'
CINZA='\033[1;90m'
RESET='\033[0m'

# Diretório base (home do usuário)
BASE_DIR="$HOME"
LOG_FILE="$BASE_DIR/speedtest.log"
TEMP_FILE="$BASE_DIR/temp_speedtest_result.txt"
SERVERS_FILE="$BASE_DIR/servers.txt"

# Trap para limpar arquivos temporários ao sair
trap 'rm -f "$TEMP_FILE" "$SERVERS_FILE" "$BASE_DIR/result_*.txt"' EXIT

# Captura tempo de início
start_time=$(date +%s)

# Verifica parâmetros
if [[ -z "$1" ]]; then
  echo -e "${VERMELHO}Informe pelo menos a meta de download a ser atingida.${RESET}"
  echo ""
  echo "Uso:"
  echo "   ./speedtest-full.sh [download] [upload]"
  echo ""
  echo "Exemplos:"
  echo "   ./speedtest-full.sh 500 500"
  echo "   ./speedtest-full.sh 500"
  exit 1
fi

# Pegando parâmetros de download e upload
META_DOWNLOAD=$1
META_UPLOAD=$2

echo -e "${VERMELHO}⚠ ATENÇÃO!${RESET} Não execute muitas vezes para evitar bloqueios."
read -p "Se estiver de acordo, pressione ENTER para começar..."
echo ""

echo -e "${ROXO}Pegando lista de servidores...${RESET}"
echo ""

# Pegando servdores próximos
server_output=$(speedtest --servers 2>&1)

if echo "$server_output" | grep -q "Too many requests received"; then
  echo ""
  echo -e "${VERMELHO}⚠ AVISO: o limite de testes foi excedido já na listagem de servidores. Tente novamente após 1h.${RESET}"
  echo "$server_output" >> "$LOG_FILE"
  echo ""
  exit 1
fi

echo "$server_output" | awk '/^[[:space:]]*[0-9]+/ {
    id=$1; $1=""; sub(/^ +/, "", $0); print id "|" $0
}' > "$SERVERS_FILE"

echo ""
cat "$SERVERS_FILE"
echo -e "\n----\n"
echo -e "${ROXO}Analisando velocidade...${RESET}"
echo ""
> "$LOG_FILE"

best_download=0
best_upload=0
best_download_info=""
best_upload_info=""

spinner_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

while IFS='|' read -r id name; do
  printf "• %s (%s): ${CINZA}Aguarde...${RESET}" "$name" "$id"
  sleep 1

  # Executando teste no servidor atual
  TMP_RESULT="$BASE_DIR/result_$id.txt"
  (speedtest -s "$id" > "$TMP_RESULT" 2>&1) &
  pid=$!

  # spinner
  i=0
  while kill -0 $pid 2>/dev/null; do
    printf "\r• %s (%s): ${CINZA}Executando testes %s  ${RESET}" "$name" "$id" "${spinner_chars[$i]}"
    i=$(((i + 1) % ${#spinner_chars[@]}))
    sleep 0.1
  done

  wait $pid
  result=$(<"$TMP_RESULT")
  rm -f "$TMP_RESULT"

  # Limpa linha do spinner antes de imprimir o resultado
  printf "\r%-80s\r" ""

  if echo "$result" | grep -q "Too many requests received"; then
    echo ""
    echo -e "${VERMELHO}⚠ AVISO: o limite de testes foi excedido. Tente novamente daqui pelo menos 1 hora.${RESET}"
    echo "$result" >> "$LOG_FILE"
    break
  fi

  if [[ -z "$result" || "$result" != *"Speedtest by Ookla"* ]]; then
    echo -e "${VERMELHO}⚠${RESET} $name ($id): ${VERMELHO}Falha no teste${RESET}"
    echo "$result" >> "$LOG_FILE"
    continue
  fi

  echo "$result" >> "$LOG_FILE"
  echo "$result" > "$TEMP_FILE"
  sed -i 's/\r//' "$TEMP_FILE"

  # Pega os dados do teste
  ping=$(grep -oP 'Idle Latency:\s+\K[0-9.]+' "$TEMP_FILE")
  download=$(grep -m 1 "Download:" "$TEMP_FILE" | awk '{print $2}')
  upload=$(grep -m 1 "Upload:" "$TEMP_FILE" | awk '{print $2}')

  if [[ -z "$download" || "$download" == "FAILED" ]]; then
    echo -e "${VERMELHO}⚠${RESET} $name ($id): ${VERMELHO}Falha no teste${RESET}"
    continue
  fi

  echo -e "• $name ($id): Ping ${CIANO}${ping:-N/A} ms${RESET} | Download ${AZUL}${download} Mbps${RESET} | Upload ${VERDE}${upload:-N/A} Mbps${RESET}"

  if (( $(echo "$download > $best_download" | bc -l) )); then
    best_download=$download
    best_download_info="$name ($id)\nPing: ${CIANO}${ping:-N/A} ms${RESET}\nDownload: ${AZUL}$download Mbps${RESET}\nUpload: ${VERDE}${upload:-N/A} Mbps${RESET}"
  fi

  if [[ -n "$upload" && "$upload" =~ ^[0-9.]+$ ]]; then
    if (( $(echo "$upload > $best_upload" | bc -l) )); then
      best_upload=$upload
      best_upload_info="$name ($id)\nPing: ${CIANO}${ping:-N/A} ms${RESET}\nDownload: ${AZUL}$download Mbps${RESET}\nUpload: ${VERDE}$upload Mbps${RESET}"
    fi
  fi

  if [[ -n "$META_UPLOAD" ]]; then
    if (( $(echo "$download >= $META_DOWNLOAD" | bc -l) && $(echo "$upload >= $META_UPLOAD" | bc -l) )); then
      echo ""
      echo -e "${ROXO}Meta de download e upload atingidas. Encerrando testes.${RESET}"
      break
    fi
  else
    if (( $(echo "$download >= $META_DOWNLOAD" | bc -l) )); then
      echo ""
      echo -e "${ROXO}Meta de download atingida. Encerrando testes.${RESET}"
      break
    fi
  fi

done < "$SERVERS_FILE"

end_time=$(date +%s)
duration=$((end_time - start_time))

echo -e "\n----\n"
echo -e "${ROXO}Melhor velocidade de ${AZUL}Download${RESET}"
echo -e "$best_download_info"
echo -e "\n${ROXO}Melhor velocidade de ${VERDE}Upload${RESET}"
echo -e "$best_upload_info"
echo -e "\n${ROXO}Tempo total de execução: $duration segundos${RESET}"

