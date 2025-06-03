# -- Configuracoes -------------------------------------------------------------
# Share com users.conf e onde ficara o arquivo de estado por usuario
$usuario     = (Get-CimInstance Win32_ComputerSystem).UserName.Split("\\")[-1]
$sharePath   = "\\server\caminho"
$arquivoConf = Join-Path $sharePath "users.conf"
$logDir      = Join-Path $sharePath "Logs"
$logFile     = Join-Path $logDir "$usuario.log"
$estadoFile  = Join-Path $logDir "$usuario.json"
$nomePC      = $env:COMPUTERNAME
$ip          = (Get-NetIPAddress -AddressFamily IPv4 |
                 Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' }
               ).IPAddress

# Garante diretorio de logs e estado
if (-not (Test-Path $logDir)) {
    try { New-Item $logDir -ItemType Directory -Force | Out-Null }
    catch { Write-Error "Erro criando diretorio de logs em '$logDir': $_"; exit 1 }
}

function Escrever-Log {
    param([string]$mensagem)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    try {
        "$ts - $mensagem" | Out-File $logFile -Append -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Error "Falha ao gravar log: $_"
    }
}

# -- Reset diario as 23:00 (via agendamento externo, se necessario usar crontab direto no servidor.) ------------
# Descomentar e ajustar conforme necessidade
# $now = Get-Date
# if ($now.Hour -eq 23) {
#     "" | Out-File $estadoFile -Encoding UTF8
#     Escrever-Log "Reset diario do $usuario.json realizado."
# }

# -- Carrega configuracao de tempo maximo ------------------------------------
if (-not (Test-Path $arquivoConf)) {
    Escrever-Log "Arquivo de configuracao nao encontrado: $arquivoConf"
    exit
}

$linha = Get-Content $arquivoConf | Where-Object {
    $_.Split(";")[0].ToLower() -eq $usuario.ToLower()
}
if (-not $linha) {
    Escrever-Log "Usuario '$usuario' sem configuracao em users.conf. $ip / $nomePC"
    exit
}

$partes = $linha.Split(";")
if ($partes.Count -lt 2) {
    Escrever-Log "Linha malformada para '$usuario': $linha"
    exit
}

try {
    $maxDuration = [TimeSpan]::Parse($partes[1])
} catch {
    Escrever-Log "Duracao invalida para '$usuario': $($partes[1])"
    exit
}
$maxSeconds = $maxDuration.TotalSeconds

# -- Carrega ou inicializa estado do usuario --------------------------------
if (Test-Path $estadoFile) {
    try {
        $stateJson = Get-Content $estadoFile -Raw | ConvertFrom-Json
        $userState = [PSCustomObject]@{
            ConsumedSeconds = [double]$stateJson.ConsumedSeconds
            LastCheck       = if ($stateJson.LastCheck) { [DateTime]::Parse($stateJson.LastCheck) } else { $null }
            Blocked         = [bool]$stateJson.Blocked
        }
    } catch {
        Escrever-Log "Erro carregando estado de '$estadoFile': $_"; exit
    }
} else {
    $userState = [PSCustomObject]@{
        ConsumedSeconds = 0
        LastCheck       = $null
        Blocked         = $false
    }
}

# -- Se ja estiver bloqueado -------------------------------------------------
if ($userState.Blocked) {
    Escrever-Log "Usuario '$usuario' bloqueado permanentemente. Forcando logoff. $ip / $nomePC"
    msg * "SEU TURNO CHEGOU AO FIM. LOGIN BLOQUEADO !"
    Start-Sleep -Seconds 10

    $sess = (quser /server:localhost 2>$null) |
            Where-Object { $_ -match "\b$usuario\b" }
    if ($sess -match "^\s*\S+\s+\S+\s+(\d+)") {
        logoff $matches[1] /server:localhost
    }
    exit
}

# -- Verifica sessao atual ---------------------------------------------------
$sessionLine = (quser /server:localhost 2>$null) |
               Where-Object { $_ -match "\b$usuario\b" }
if (-not $sessionLine) {
    # nao esta logado: limpa LastCheck e salva estado
    $userState.LastCheck = $null
    $saveObj = @{ ConsumedSeconds = $userState.ConsumedSeconds; LastCheck = $null; Blocked = $userState.Blocked }
    $saveObj | ConvertTo-Json | Set-Content -Path $estadoFile -Encoding UTF8
    Escrever-Log "Sem sessao ativa para '$usuario'. Estado preservado. $ip / $nomePC"
    exit
}

# -- Acumula tempo desde ultima verificacao ----------------------------------
$now = Get-Date
if (-not $userState.LastCheck) { $userState.LastCheck = $now }

$delta = ($now - $userState.LastCheck).TotalSeconds
$userState.ConsumedSeconds += $delta
$userState.LastCheck       = $now

# -- Salva estado atualizado ------------------------------------------------
$saveObj = @{ 
    ConsumedSeconds = $userState.ConsumedSeconds;
    LastCheck       = $userState.LastCheck.ToString("o");
    Blocked         = $userState.Blocked
}
$saveObj | ConvertTo-Json | Set-Content -Path $estadoFile -Encoding UTF8

# -- Decide acoes de aviso e logoff -----------------------------------------
$remaining = $maxSeconds - $userState.ConsumedSeconds
if ($remaining -le 0) {
    $userState.Blocked = $true
    $saveObj.Blocked = $true
    $saveObj | ConvertTo-Json | Set-Content -Path $estadoFile -Encoding UTF8

    Escrever-Log "Tempo total excedido. Bloqueando '$usuario' e desconectando. $ip / $nomePC"
    msg * "LOGOFF EM 20 SEGUNDOS... Voce excedeu seu tempo total de sessao de $maxDuration."
    Start-Sleep -Seconds 20

    if ($sessionLine -match "^\s*\S+\s+\S+\s+(\d+)") {
        logoff $matches[1] /server:localhost
    }
    exit
}

if ($remaining -le 300) {
    $mins = [int]($remaining / 60)
    Escrever-Log "Aviso: faltam $mins minutos do limite ($maxDuration) para $usuario. $ip / $nomePC"
    msg * "Faltam $mins minutos. Apos esse tempo sera feito logoff automaticamente!"
} else {
    Escrever-Log "Sessao OK - $usuario - restante: $([TimeSpan]::FromSeconds($remaining))."
}
