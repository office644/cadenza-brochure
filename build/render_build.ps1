$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$base='C:\Users\office\cadenza-brochure\build'
$html = [System.IO.File]::ReadAllText((Join-Path $base 'print.html'), [System.Text.Encoding]::UTF8)
# embed every image as base64 (remote http, file:///, or relative-to-base)
$srcs = [regex]::Matches($html, 'src="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
$wc = New-Object System.Net.WebClient
$wc.Headers.Add('User-Agent','Mozilla/5.0')
foreach($u in $srcs){
  if($u -match '^data:'){ continue }
  try {
    if($u -like 'file:///*'){
      $p = [Uri]::UnescapeDataString($u.Substring(8)) -replace '/','\'
      $bytes = [System.IO.File]::ReadAllBytes($p)
    } elseif($u -like 'http*'){
      $bytes = $wc.DownloadData($u)
    } else {
      $p = Join-Path $base ($u -replace '/','\')
      $bytes = [System.IO.File]::ReadAllBytes($p)
    }
    $clean = ($u -replace '\?.*$','')
    $ext = ([System.IO.Path]::GetExtension($clean)).ToLower()
    $mime = switch($ext){ '.webp'{'image/webp'} '.png'{'image/png'} '.jpg'{'image/jpeg'} '.jpeg'{'image/jpeg'} '.svg'{'image/svg+xml'} '.gif'{'image/gif'} default{'image/png'} }
    $b64 = [Convert]::ToBase64String($bytes)
    $html = $html.Replace('src="'+$u+'"', 'src="data:'+$mime+';base64,'+$b64+'"')
    Write-Output ("OK   " + [math]::Round($bytes.Length/1KB).ToString().PadLeft(5) + " KB  " + $u.Substring(0,[math]::Min(70,$u.Length)))
  } catch {
    Write-Output ("FAIL " + $u + "  ::  " + $_.Exception.Message)
  }
}
$out = Join-Path $base 'print_embed.html'
[System.IO.File]::WriteAllText($out, $html, (New-Object System.Text.UTF8Encoding($false)))
$left = ([regex]::Matches($html,'src="(https?://|file:///)')).Count
Write-Output ("---- embed html KB: " + [math]::Round((Get-Item $out).Length/1KB) + " | remaining remote/file srcs: " + $left)
