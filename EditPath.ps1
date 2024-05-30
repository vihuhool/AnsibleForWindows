$newPath = "$env:SYSTEMROOT\System32\WindowsPowerShell\v1.0\"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)

if ($currentPath -notlike "*$newPath*") {
    $updatedPath = "$currentPath;$newPath"
    [System.Environment]::SetEnvironmentVariable("PATH", $updatedPath, [System.EnvironmentVariableTarget]::Machine)
    Write-Output "Path updated successfully."
} else {
    Write-Output "Path already contains PowerShell path."
}
