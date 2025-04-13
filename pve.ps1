
$pve_info = Get-Content "$PSScriptRoot/pve.json" | convertfrom-json
$default_node = "pve"

function Invoke-PveEndpoint($endpoint, $method="GET", $data) {
	$url = "$($pve_info.base_url)/$endpoint"
	if (($null -ne $data) -and ($data -isnot [string])) {
		$data = $data | convertto-json -depth 20
	}
	write-host $url
	try {
		Invoke-WebRequest -Method $method -Body $data -Headers @{"Authorization" = "PVEAPIToken=$($pve_info.token_id)=$($pve_info.secret)"} $url -SkipHeaderValidation -SkipCertificateCheck | % content | convertfrom-json
	} catch {
		write-host $_.Exception.Response.StatusCode
		write-host $_.Exception.Response.ReasonPhrase
		throw $_
	}
}

function Get-PveVersion() {
	Invoke-PveEndpoint version | % data
}

function Get-PveVms($node=$default_node) {
	Invoke-PveEndpoint "nodes/$node/qemu" | % data
}
function Get-PveVm($id, $node=$default_node) {
	Invoke-PveEndpoint "nodes/$node/qemu/$id" | % data
}
function Get-PveVmConfig($id, $node=$default_node) {
	Invoke-PveEndpoint "nodes/$node/qemu/$id/config" | % data
}

function Get-PveHosts($node=$default_node) {
	Invoke-PveEndpoint "nodes/$node/hosts" | % data
}

function Get-PveVmConfig($vmid, $node=$default_node) {
    Invoke-PveEndpoint "nodes/$node/qemu/$vmid/config" | % data
}

function Remove-PveDisk($node, $storage, $volume) {
    # The Proxmox API for removing (destroying) a volume is:
    #   DELETE /api2/json/nodes/<node>/storage/<storage>/content/<volume>
    # If you want to force removal, you might pass query params, e.g., ?force=1 
    $endpoint = "nodes/$node/storage/$storage/content/$volume"
    Invoke-PveEndpoint $endpoint "DELETE"
}

function Wipe-PveVmDisks($vmid, $node=$default_node) {
    $config = Get-PveVmConfig $vmid $node

    # Each disk line could be scsi0, ide0, sata0, etc. 
    # We'll look for lines that contain "<storage>:<volume>".
    $diskKeys = $config.PSObject.Properties |
        Where-Object { $_.Name -match '^(scsi)\d+' } |
        Select-Object -ExpandProperty Name

    write-host $diskKeys
    return

    foreach ($dk in $diskKeys) {
        $value = $config.$dk
        # Example: "local-lvm:vm-100-disk-0,size=20G"

        # Split on colon to get <storage> and the rest (<volume>,size=...)
        $parts = $value -split ':', 2
        if ($parts.Count -lt 2) {
            continue
        }
        $storage = $parts[0]
        $rest    = $parts[1]  # e.g. "vm-100-disk-0,size=20G"

        # The volume is the substring before the first comma
        $volumeParts = $rest -split ',', 2
        $volume = $volumeParts[0] # e.g. "vm-100-disk-0"

        Write-Host "Removing ${storage}:${volume} from VM $vmid..."
        Remove-PveDisk $node $storage $volume
    }
}

#$data = Get-PveVms
#$data | convertto-json -depth 20

#$data = Get-PveVmConfig $data[0].vmid
#$data | convertto-json -depth 20


