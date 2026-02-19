# 🔧 INSTRUÇÕES PARA ACESSAR LOGS DO BISYNC NA VPS

**Problema:** SSH automático não está funcionando, mas precisamos dos logs do Bisync.

## Opção 1: Console Web Digital Ocean (RECOMENDADO)

### Passo 1: Acessar Console
1. Abra: https://cloud.digitalocean.com/
2. Faça login
3. Vá em **Droplets** → **vps-ariel-wulkan**
4. Clique em **"Access"** no menu lateral
5. Clique em **"Launch Droplet Console"**

### Passo 2: Executar Comandos
No console que abrir, execute os seguintes comandos e cole os resultados aqui:

```bash
# 1. Ver últimas 50 linhas do log principal do Bisync
tail -50 /root/logs/bisync.log

# 2. Ver erros do Bisync
tail -30 /root/logs/bisync_errors.log

# 3. Verificar lock files
ls -la /root/.cache/rclone/bisync/

# 4. Verificar processos bisync rodando
ps aux | grep rclone | grep -v grep

# 5. Ver status do cron
crontab -l | grep bisync

# 6. Ver últimas execuções do watchdog
tail -20 /var/log/bisync_watchdog.log
```

---

## Opção 2: Corrigir SSH (Alternativa)

Se preferir consertar o SSH agora:

### Método A: Usar Console Web para Adicionar Sua Chave Pública
1. Acesse o console web (passos acima)
2. No terminal, execute:
```bash
cat /root/.ssh/authorized_keys
```
3. Compare com sua chave pública local em: `C:\Users\ariel\.ssh\id_rsa.pub`
4. Se diferente, adicione a chave local:
```bash
echo "CONTEÚDO_DA_SUA_CHAVE_PUBLICA" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### Método B: Resetar Senha Root (Digital Ocean)
1. No painel da VPS, clique em **"Access"**
2. Clique em **"Reset Root Password"**
3. Senha será enviada por email
4. Use a senha para conectar via SSH

---

## Opção 3: API Digital Ocean (Limitada)

Posso usar a API para:
- ✅ Ver status da VPS
- ✅ Criar snapshots
- ✅ Reiniciar a VPS
- ❌ Não posso executar comandos ou ler logs

---

## 🎯 RECOMENDAÇÃO

**Use a Opção 1 (Console Web)** - é a mais rápida!

Copie e cole aqui os resultados dos comandos e eu analiso o problema do Bisync.

---

## 📋 Informações da VPS

- **ID:** 551527453
- **Nome:** vps-ariel-wulkan
- **Status:** active ✅
- **IP:** 143.198.9.121
- **Provider:** Digital Ocean
