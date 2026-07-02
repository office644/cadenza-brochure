$ErrorActionPreference='Continue'
$base='C:\Users\office\cadenza-brochure\build'
$status=Join-Path $base 'render_status.txt'
'START' | Out-File $status
# 1) build embed (base64 all images)
& (Join-Path $base 'render_build.ps1') | Out-Null
# 2) render
$edge='C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$in='file:///' + ($base.Replace('\','/')) + '/print_embed.html'
$pdf=Join-Path $base 'out.pdf'
try{ if(Test-Path $pdf){ [System.IO.File]::Delete($pdf) } }catch{}
$prof=Join-Path $base ('ep_'+(Get-Random))
$a=@('--headless=new','--disable-gpu','--disable-dev-shm-usage','--disk-cache-size=1','--no-first-run','--no-default-browser-check',"--user-data-dir=$prof",'--virtual-time-budget=30000','--run-all-compositor-stages-before-draw','--no-pdf-header-footer',"--print-to-pdf=$pdf",$in)
$p=Start-Process -FilePath $edge -ArgumentList $a -PassThru -WindowStyle Hidden
$ok=$false
for($t=0;$t -lt 220;$t++){
  Start-Sleep -Seconds 1
  if(Test-Path $pdf){
    $s1=(Get-Item $pdf).Length; Start-Sleep -Seconds 2; $s2=(Get-Item $pdf).Length
    if($s1 -gt 100000 -and $s1 -eq $s2){ $ok=$true; break }
  }
  if($p.HasExited){ if((Test-Path $pdf) -and (Get-Item $pdf).Length -gt 100000){ $ok=$true }; break }
}
try{ if(!$p.HasExited){ $p.Kill(); Start-Sleep -Seconds 2 } }catch{}
if($ok -and (Test-Path $pdf)){
  Copy-Item $pdf 'C:\Users\office\cadenza-brochure\CADENZA-Brochure.pdf' -Force
  $dlDir=Join-Path $env:USERPROFILE 'Downloads'
  $fresh=Join-Path $dlDir ('CADENZA-Brochure-' + (Get-Date -Format 'HHmm') + '.pdf')
  Copy-Item $pdf $fresh -Force
  $lockNote=''
  try{ Copy-Item $pdf (Join-Path $dlDir 'CADENZA-Brochure.pdf') -Force -ErrorAction Stop }catch{ $lockNote=' MAIN_DL_LOCKED' }
  ('RENDER_OK ' + [math]::Round((Get-Item $pdf).Length/1MB,2) + 'MB ' + (Get-Date -Format 'HH:mm:ss') + ' fresh=' + [System.IO.Path]::GetFileName($fresh) + $lockNote) | Out-File $status
} else {
  ('RENDER_FAIL ' + (Get-Date -Format 'HH:mm:ss')) | Out-File $status
}
try{[System.IO.Directory]::Delete($prof,$true)}catch{}
