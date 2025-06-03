# 🛠️ Guia Rápido de Configuração.

## 1. 🗂️ GPO (Group Policy Object)

### Criar a pasta do script e copiar o arquivo

1. Acesse o **Editor de Gerenciamento de Política de Grupo** (`gpedit.msc`).
2. Navegue até:
   ```
   Configurações do Computador > Preferências > Configurações do Windows > Arquivos
   ```
3. Crie uma nova ação **Copiar**:
   - **Origem:** `\\caminho_da_rede\tempocorrido.ps1`
   - **Destino:** `C:\Script\tempocorrido.ps1`

---

## 2. ⏱️ Tarefa Agendada (Agendador de Tarefas)

### Criar tarefa que executa o script

1. Vá para:
   ```
   Configurações do Computador > Configurações do Windows > Tarefas Agendadas
   ```
2. Crie uma tarefa chamada `tela_de_bloqueio`:
   - **Ação:** Iniciar um programa
   - **Programa/script:** `powershell.exe`
   - **Argumentos:** `-ExecutionPolicy Bypass -File C:\Script\tempocorrido.ps1`
   - **Agendamentos:**
     - Ao logon
     - A cada 5 minutos (gatilho de repetição)

---

## 3. 🧾 Exemplo de `Users.config`

```txt
user1;06:00
user2;05:30
user3;04:45
```

---

## 4. 🔁 Cron no servidor (Linux)

Adicionar no `/etc/cron.d/limpeza_json`:

```bash
0 23 * * * root find /mnt/screenblock/Logs -name "*.json" -delete
```

---

## ✅ Checklist Final

- [ ] GPO criada com cópia do script
- [ ] Tarefa agendada criada corretamente
- [ ] `Users.config` configurado
- [ ] Pasta `Logs/` com permissões de escrita
- [ ] Cron configurado para limpar `.json`