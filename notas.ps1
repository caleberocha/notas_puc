param($Proxy)
$logado = $false
$page = ""
try {
	while(!$logado) {
		$cred = Get-Credential -Message "Insira as credenciais de acesso à rede da PUCRS."
		if(!$cred) {
			throw "Credenciais não inseridas."
		}
		$web = Invoke-WebRequest https://webapp.pucrs.br/appgw/auth/portal -SessionVariable session -Proxy $proxy
		$web = Invoke-WebRequest https://webapp.pucrs.br/appgw/portal/wsauth -Method Post -Body @{username = $cred.UserName; password = $cred.GetNetworkCredential().Password} -MaximumRedirection 0 -WebSession $session -Proxy $proxy
		if($web.Headers.Location -match "auth/error\?error=(.*)") {
			Write-Host -ForegroundColor Red -BackgroundColor Black ([System.Web.HttpUtility]::UrlDecode($Matches[1]))
		}
		elseif($web.StatusCode -ne 307) {
			throw "Erro inesperado: É esperado o código HTTP 307, mas foi retornado $($web.StatusCode)."
		} else {
			$logado = $true
			$page = $web.Headers.Location
		}
	}
} catch {
	throw $_
}

while($true) {
    $notas = @()
    $a = Invoke-WebRequest $page -SessionVariable session -Proxy $proxy
    $a = Invoke-WebRequest https://webapp.pucrs.br/consulta/servlet/consulta.aluno.Publicacoes?param=2564760 -WebSession $session -Proxy $proxy

    $table = $a.ParsedHtml.getElementsByTagName("table") | ? {$_.className -eq "graus border"}
    for($i = 1; $i -lt $table.childNodes[0].childNodes.length - 1; $i += 3) {
        $cells = $table.childNodes[0].childNodes[$i].childNodes
        $cellsNext = $table.childNodes[0].childNodes[$i+1].childNodes

        $graus = @()
        $r = $cells[2].childNodes[0].childNodes[0].childNodes[0]
        $rn = $cells[2].childNodes[0].childNodes[0].childNodes[1]
        for($j = 0; $j -lt $r.childNodes.length; $j++) {
            $graus += "$($r.childNodes[$j].innerText) = $($rn.childNodes[$j].innerText)"
        }

        $notas += 1 | Select-Object @{n="Turma"; e={$cells[0].innerText}},
                                    @{n="Disciplina"; e={$cells[1].innerText}},
                                    @{n="Graus"; e={$graus -join ", "}},
                                    @{n="Aulas"; e={$cells[3].innerText}},
                                    @{n="Faltas"; e={$cells[4].innerText}},
                                    @{n="G1"; e={$cells[5].innerText}},
                                    @{n="Data G1"; e={$cellsNext[0].innerText}},
                                    @{n="G2"; e={$cells[6].innerText}},
                                    @{n="Data G2"; e={$cellsNext[1].innerText}},
                                    @{n="Final"; e={$cells[7].innerText}}

    }
	Clear-Host
    $notas | ft -AutoSize

    timeout /t 300
}