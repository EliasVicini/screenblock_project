# Controle de Sessão por Usuário - ScreenBlock

Este projeto é um script PowerShell utilizado para controlar o tempo de sessão de usuários em estações de trabalho Windows dentro de uma rede corporativa. O objetivo é limitar o tempo de uso por usuário, forçando logoff quando o tempo exceder o configurado.

---

## 📂 Estrutura do Projeto

```
.
├── tempocorrido.ps1        # Script principal
├── Users.config            # Configuração de tempo por usuário (ex: usuario;HH:MM)
├── Logs/                   # Diretório onde ficam os arquivos .json e logs .log
```

---

## ⚙️ Funcionamento

- O script é executado via GPO no logon e a cada 5 minutos.
- Ele consulta o `Users.config` para obter o tempo permitido por usuário.
- Cada usuário tem seu próprio arquivo JSON (`usuario.json`) contendo:
  - Tempo acumulado (`ConsumedSeconds`)
  - Última verificação (`LastCheck`)
  - Status de bloqueio (`Blocked`)
- Quando o tempo permitido é excedido, o script envia uma mensagem e força logoff.
- Logs são salvos em `Logs/usuario.log`.

---

## ⏲️ Cron de limpeza

Um cron no servidor limpa todos os arquivos `.json` às 23h diariamente:

```bash
0 23 * * * root find /mnt/screenblock/Logs -name "*.json" -delete
```

---

## 🖥️ Requisitos

- Windows com PowerShell
- Compartilhamento de rede acessível para `Users.config` e `Logs/`
- Permissão de escrita no caminho `\servidor\screenblock\Logs`

---

## 🚀 Como usar

1. Copie o script para `C:\Script\tempocorrido.ps1` via GPO.
2. Crie agendamento de tarefa `tela_de_bloqueio` para rodar a cada 5 minutos.
3. Configure `Users.config` com os tempos por usuário.
4. (Opcional) Use cron no servidor para reset diário dos JSONs.

---

## 📄 Licença

Este projeto é interno e destinado ao uso em ambientes corporativos. Pode ser adaptado conforme a necessidade de cada organização.