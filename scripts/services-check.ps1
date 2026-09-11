# Checks services running on Computer

Write-Host "=== Domain Health Check ===" -ForegroundColor Cyan

Get-Service -Name "DhcpServer", "DNS", "NTDS"

$scope = Get-DhcpServerv4Scope -ComputerName "DC01"
if ($scope.State -eq 'Active') {
    Write-Host "DHCP scope: OK" -ForegroundColor Green
} else {
    Write-Host "DHCP scope: INACTIVE - problem!" -ForegroundColor Red
}



$dnsResult = Resolve-DnsName corp.lab

if ($dnsResult.IPAddress -eq '192.168.20.10') {
    Write-Host "DNS Result: OK" -ForegroundColor Green
} else {

    Write-Host "DNS Resolution Incomplete - problem!" -ForegroundColor Red

}

