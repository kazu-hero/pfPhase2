param(
    [Parameter(Mandatory=$true)]
    [string]$OrgAlias,
    [string]$OutputRoot = "Salesforce_DevDocs/org-schema"
)

$ErrorActionPreference = "Stop"

# コンソールエンコーディングをUTF-8に設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function New-DirectoryIfMissing {
    param([string]$Path)

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }
}

function Export-SfQueryToCsv {
    param(
        [string]$OrgAlias,
        [string]$Soql,
        [string]$OutputPath
    )

    $raw = & sf data query -o $OrgAlias -q $Soql --result-format csv
    if ($LASTEXITCODE -ne 0) {
        throw "sf data query failed for [$OutputPath]."
    }

    $csvLines = @(
        $raw |
        ForEach-Object { $_.ToString() } |
        Where-Object {
            $_ -and
            $_ -notmatch "^Querying Data\.\.\. done$"
        }
    )

    $content = if ($csvLines.Count -eq 0) { "" } else { $csvLines -join "`r`n" }
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $content, $utf8WithBom)
}

function Export-SObjectDescribeToJson {
    param(
        [string]$OrgAlias,
        [string]$SObjectApiName,
        [string]$OutputPath
    )

    $raw = & sf sobject describe -o $OrgAlias -s $SObjectApiName --json
    if ($LASTEXITCODE -ne 0) {
        throw "sf sobject describe failed for [$SObjectApiName]."
    }

    $content = ($raw | Out-String).Trim()
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($OutputPath, $content, $utf8WithBom)
}

$workspaceRoot = (Get-Location).Path
$baseDir = Join-Path $workspaceRoot $OutputRoot
$orgDir = Join-Path $baseDir $OrgAlias
$latestDir = Join-Path $orgDir "latest"
$historyRootDir = Join-Path $orgDir "history"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$historyDir = Join-Path $historyRootDir $timestamp
$historyCustomDescribeDir = Join-Path $historyDir "describes/custom"
$latestCustomDescribeDir = Join-Path $latestDir "describes/custom"

New-DirectoryIfMissing -Path $baseDir
New-DirectoryIfMissing -Path $orgDir
New-DirectoryIfMissing -Path $latestDir
New-DirectoryIfMissing -Path $historyRootDir
New-DirectoryIfMissing -Path $historyDir
New-DirectoryIfMissing -Path $historyCustomDescribeDir

$queries = @(
    @{
        FileName = "entity-definitions.csv"
        Soql = "SELECT QualifiedApiName, Label, KeyPrefix, DurableId, NamespacePrefix, IsCustomizable, IsCustomSetting FROM EntityDefinition ORDER BY QualifiedApiName"
    },
    @{
        FileName = "custom-objects.csv"
        Soql = "SELECT QualifiedApiName, Label, KeyPrefix, DurableId, NamespacePrefix FROM EntityDefinition WHERE (QualifiedApiName LIKE '%__c' OR QualifiedApiName LIKE '%__mdt') ORDER BY QualifiedApiName"
    }
)

if (Test-Path -Path (Join-Path $latestDir "*")) {
    Remove-Item -Path (Join-Path $latestDir "*") -Recurse -Force
}

New-DirectoryIfMissing -Path $latestCustomDescribeDir

foreach ($query in $queries) {
    $historyPath = Join-Path $historyDir $query.FileName
    Export-SfQueryToCsv -OrgAlias $OrgAlias -Soql $query.Soql -OutputPath $historyPath
    Copy-Item -Path $historyPath -Destination (Join-Path $latestDir $query.FileName) -Force
}

$customObjectsCsv = Join-Path $historyDir "custom-objects.csv"
$customObjects = @()
if (Test-Path -Path $customObjectsCsv) {
    $customObjects = Import-Csv -Path $customObjectsCsv | Select-Object -ExpandProperty QualifiedApiName
}

$fieldSummaryRows = @()
$describeFailures = @()

foreach ($customObject in $customObjects) {
    $historyDescribePath = Join-Path $historyCustomDescribeDir ("{0}.json" -f $customObject)
    $latestDescribePath = Join-Path $latestCustomDescribeDir ("{0}.json" -f $customObject)

    try {
        Export-SObjectDescribeToJson -OrgAlias $OrgAlias -SObjectApiName $customObject -OutputPath $historyDescribePath
        Copy-Item -Path $historyDescribePath -Destination $latestDescribePath -Force

        $describeJson = Get-Content -Path $historyDescribePath -Raw | ConvertFrom-Json
        foreach ($field in @($describeJson.result.fields)) {
            $referenceTo = ""
            if ($null -ne $field.referenceTo -and $field.referenceTo.Count -gt 0) {
                $referenceTo = ($field.referenceTo -join ";")
            }

            $fieldSummaryRows += [PSCustomObject]@{
                ObjectApiName = $customObject
                FieldApiName = $field.name
                Label = $field.label
                Type = $field.type
                IsCustom = $field.custom
                IsNillable = $field.nillable
                IsCalculated = $field.calculated
                Length = $field.length
                Precision = $field.precision
                Scale = $field.scale
                ReferenceTo = $referenceTo
            }
        }
    }
    catch {
        $describeFailures += $customObject
        Write-Warning "Describe failed for [$customObject]."
    }
}

$fieldSummaryHistoryPath = Join-Path $historyDir "custom-field-summary.csv"
$fieldSummaryLatestPath = Join-Path $latestDir "custom-field-summary.csv"

if ($fieldSummaryRows.Count -eq 0) {
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($fieldSummaryHistoryPath, "", $utf8WithBom)
} else {
    $tempCsv = $fieldSummaryRows | Sort-Object ObjectApiName, FieldApiName | ConvertTo-Csv -NoTypeInformation
    $csvContent = $tempCsv -join "`r`n"
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($fieldSummaryHistoryPath, $csvContent, $utf8WithBom)
}

Copy-Item -Path $fieldSummaryHistoryPath -Destination $fieldSummaryLatestPath -Force

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToString("o")
    orgAlias = $OrgAlias
    outputRoot = $OutputRoot
    historyPath = $historyDir
    latestPath = $latestDir
    files = @($queries.FileName)
    customObjectCount = $customObjects.Count
    describeFailureCount = $describeFailures.Count
    describeFailures = $describeFailures
}

$manifestPath = Join-Path $historyDir "manifest.json"
$manifestLatestPath = Join-Path $latestDir "manifest.json"
$manifestJson = $manifest | ConvertTo-Json -Depth 4
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($manifestPath, $manifestJson, $utf8WithBom)
Copy-Item -Path $manifestPath -Destination $manifestLatestPath -Force

Write-Host "Schema export completed."
Write-Host "- Org: $OrgAlias"
Write-Host "- Latest: $latestDir"
Write-Host "- History snapshot: $historyDir"
Write-Host "- Custom object describes: $($customObjects.Count - $describeFailures.Count)/$($customObjects.Count)"
