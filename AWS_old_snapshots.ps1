# Install AWS Tools for PowerShell if not already installed
# Install-Module -Name AWSPowerShell -Force -AllowClobber

# Specify the output CSV file
$outputCsvFile = "snapshots_info.csv"

# Get all AWS profiles from the credentials file
$awsProfiles = Get-AWSCredential -ListProfileDetail | Select-Object -ExpandProperty ProfileName

# Create an array to store snapshot information
$snapshotInfo = @()

foreach ($profile in $awsProfiles) {
    # Set the AWS profile
    Set-AWSCredential -ProfileName $profile

    # Get all snapshots older than 30 days
    $snapshots = Get-EC2Snapshot | Where-Object { $_.StartTime -lt (Get-Date).AddDays(-30) }

    foreach ($snapshot in $snapshots) {
        # Extract relevant information
        $info = [PSCustomObject]@{
            Profile       = $profile
            Name          = ($snapshot.Tags | Where-Object { $_.Key -eq 'Name' }).Value
            VolumeId      = $snapshot.VolumeId
            SnapshotAge   = (New-TimeSpan -Start $snapshot.StartTime -End (Get-Date)).Days
            SnapshotId    = $snapshot.SnapshotId
        }

        # Add the information to the array
        $snapshotInfo += $info
    }
}

# Export snapshot information to CSV
$snapshotInfo | Export-Csv -Path $outputCsvFile -NoTypeInformation

Write-Host "Snapshot information exported to $outputCsvFile"
