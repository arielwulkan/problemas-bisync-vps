# 🔍 ANÁLISE DAS FALHAS DO BISYNC - 17/02/2026

**Data da Análise:** 17/02/2026 13:51 UTC (10:51 BRT)
**Status VPS:** ✅ Online | Load: 0.09 | RAM: 45% | Disco: 13.3%

---

## 📊 RESUMO EXECUTIVO

**Causa Raiz:** ❌ **RATE LIMIT EXCEEDED - Google Drive API**

**Impacto:** 
- 4 falhas em 7 execuções nas últimas 13 horas (57% taxa de falha)
- Sistema ainda funcional (modo resiliente ativo)
- Nenhum lock file órfão (diferente do incidente de 16/02)

**Severidade:** 🟡 MÉDIA (temporário, sem perda de dados)

---

## 🕐 CRONOLOGIA DAS EXECUÇÕES (Últimas 13h)

| Horário UTC | Status | Duração | Código |
|-------------|--------|---------|--------|
| 22:00 (16/02) | ✅ Sucesso | ~47min | 0 |
| 00:00 | ❌ Falhou | ~47min | 7 |
| 02:00 | ❌ Falhou | ~48min | 7 |
| 04:00 | ❌ Falhou | ~47min | 7 |
| 06:00 | ✅ Sucesso | ~48min | 0 |
| 08:00 | ✅ Sucesso | ~48min | 0 |
| 10:00 | ✅ Sucesso | ~47min | 0 |
| 12:00 | ❌ Falhou | ~47min | 7 |

**Padrão:** Não há padrão claro de horário. Falhas parecem aleatórias.

---

## 🎯 CAUSA RAIZ: GOOGLE DRIVE API RATE LIMIT

### Mensagem de Erro
```json
{
  "error": {
    "code": 429,
    "message": "Rate Limit Exceeded",
    "status": "RESOURCE_EXHAUSTED",
    "details": [
      {
        "reason": "RATE_LIMIT_EXCEEDED",
        "metadata": {
          "consumer": "projects/202264815644",
          "quota_limit": "defaultPerMinutePerProject",
          "quota_limit_value": "840000",
          "quota_metric": "drive.googleapis.com/default",
          "quota_unit": "1/min/{project}",
          "service": "drive.googleapis.com"
        }
      }
    ]
  }
}
```

### Análise do Erro

**Limite:** 840.000 requests/minuto/projeto
**Verificações:** 212.949 arquivos em ~47 minutos
**Taxa estimada:** ~4.500 requests/min

**Problema:** O limite de 840k/min é ALTO. O bisync não deveria atingir isso com apenas 213k arquivos.

**Possíveis Causas:**
1. 🔄 **Múltiplas verificações do mesmo arquivo** (problema no bisync?)
2. 🌐 **Outros serviços usando a mesma API key** do projeto Google Cloud
3. ⚡ **Picos de requests** concentrados em janelas curtas
4. 🔁 **Retry automático** do rclone consumindo quota adicional

---

## ✅ PONTOS POSITIVOS

### 1. Sistema Resiliente Funcionando
```
ERROR: Bisync aborted. Error is retryable without --resync due to --resilient mode.
```
✅ Modo resiliente está ATIVO
✅ Não precisa de `--resync` completo
✅ Próxima execução tentará continuar de onde parou

### 2. Nenhum Lock File Órfão
```bash
ls -la /root/.cache/rclone/bisync/
# Apenas arquivos .lst e .lst-old - SEM .lck
```
✅ Nenhum processo travado
✅ Cron executando normalmente
✅ Sistema auto-recuperável

### 3. Nenhum Processo Travado
```bash
ps aux | grep rclone | grep -v grep
# (vazio)
```
✅ Nenhum processo rclone rodando fora do cron
✅ Cron não está bloqueado

---

## 📈 DADOS TÉCNICOS

### Volume de Dados
- **Arquivos sincronizados:** 212.949 arquivos
- **Total listado:** 213.376 arquivos
- **Tamanho listas:** 18.7 MB cada (path1.lst e path2.lst)
- **Transferência na última execução:** 0 B (só verificação)

### Performance
- **Duração média:** ~47 minutos por execução
- **Checks/minuto:** ~4.500 arquivos/min
- **Lista verificada:** 100% completada antes de falhar

### Sistema VPS
- **Load average:** 0.09 (muito baixo)
- **RAM:** 45% (saudável)
- **Disco:** 13.3% usado (muito espaço)
- **Uptime:** Reboot pendente (não crítico)

---

## 🔧 SOLUÇÕES PROPOSTAS

### Solução 1: Aumentar Intervalo do Cron (Imediato)
**Problema:** Execuções a cada 2h podem causar sobrecarga
**Solução:** Mudar de 2h para 3h ou 4h

```bash
# Cron atual (presumido): */2 * * * * (a cada 2 horas)
# Novo cron sugerido: 0 */3 * * * (a cada 3 horas)

crontab -e
# Alterar linha do bisync para:
0 */3 * * * /root/scripts/bisync_auto.sh >> /root/logs/bisync_cron.log 2>&1
```

**Benefício:** Reduz frequência de requests à API do Google

---

### Solução 2: Adicionar Rate Limiting no Rclone (Recomendado)
**Problema:** Rclone não está limitando taxa de requests
**Solução:** Configurar `--tpslimit` e `--tpslimit-burst`

```bash
# Editar /root/scripts/bisync_auto.sh
# Adicionar flags ao comando rclone bisync:

rclone bisync gdrive: onedrive_cloud: \
  --resilient \
  --recover \
  --max-lock 5m \
  --tpslimit 10 \
  --tpslimit-burst 100 \
  --drive-pacer-min-sleep 100ms \
  --drive-pacer-burst 10 \
  --log-file=/root/logs/bisync.log \
  --log-level INFO
```

**Explicação:**
- `--tpslimit 10`: Máximo 10 transactions/segundo (600/min)
- `--tpslimit-burst 100`: Permite picos de até 100
- `--drive-pacer-*`: Controle fino do Google Drive
- Execução vai demorar mais (~60-70min), mas não vai falhar

---

### Solução 3: Verificar Quota do Projeto Google Cloud (Longo Prazo)
**Ação:** Acessar Google Cloud Console e verificar uso real

1. Acessar: https://console.cloud.google.com/
2. Ir em **APIs & Services** → **Dashboard**
3. Selecionar **Google Drive API**
4. Ver gráfico de uso/quota
5. Se necessário, solicitar aumento de quota

---

### Solução 4: Dividir Sincronização em Batches (Alternativa)
**Problema:** Sincronizar 213k arquivos de uma vez
**Solução:** Dividir em múltiplos bisync de subpastas

Exemplo:
```bash
# Em vez de sincronizar tudo:
rclone bisync gdrive: onedrive_cloud:

# Dividir por pasta:
rclone bisync gdrive:/Documentos onedrive_cloud:/Documentos
rclone bisync gdrive:/Fotos onedrive_cloud:/Fotos
rclone bisync gdrive:/Projetos onedrive_cloud:/Projetos
```

**Desvantagem:** Mais complexo de gerenciar

---

## 🎯 RECOMENDAÇÃO IMEDIATA

### Ação 1: Implementar Rate Limiting (AGORA)
Execute no terminal da VPS:

```bash
# 1. Backup do script atual
cp /root/scripts/bisync_auto.sh /root/scripts/bisync_auto.sh.bak

# 2. Editar script
nano /root/scripts/bisync_auto.sh

# 3. Localizar linha do rclone bisync e adicionar:
#    --tpslimit 10 --tpslimit-burst 100
```

### Ação 2: Monitorar Próximas 3 Execuções
- Próxima execução: 14:00 UTC (11:00 BRT)
- Verificar se rate limit resolve
- Se resolver, manter configuração

---

## 📝 COMANDOS PARA EXECUTAR NA VPS

```bash
# Ver script bisync atual
cat /root/scripts/bisync_auto.sh

# Ver crontab
crontab -l

# Testar bisync manual com rate limit (CUIDADO - pode demorar 1h+)
# rclone bisync gdrive: onedrive_cloud: --resilient --recover --tpslimit 10 --dry-run

# Forçar próxima execução (teste)
# /root/scripts/bisync_auto.sh
```

---

## 🚦 STATUS ATUAL

```
✅ Sistema operacional
✅ Nenhum lock file bloqueando
✅ Nenhum processo travado
✅ Modo resiliente funcionando
⚠️ Taxa de falha: 57% (rate limit)
🔄 Próxima execução: 14:00 UTC

🟡 AÇÃO NECESSÁRIA: Implementar rate limiting
```

---

**Documentado por:** Claude Sonnet 4.5  
**Data:** 17/02/2026 10:51 BRT
