param(
    [Parameter(Mandatory=$true)]
    [string]$URL, # The URL to scrape data from
    [string]$OutputPath = (Get-Location)
)

$OutputFileName = $URL.Split('/')[-1].split("?")[0] + ".csv"
$response = Invoke-WebRequest -Uri $URL
$html = $response.ParsedHtml


$anchorLinks = $html.getElementsByClassName("anchor-link")
$parametersIndex = 0
for ($i = 0; $i -lt $anchorLinks.length; $i++) {
    if ($anchorLinks[$i].getAttribute("aria-label") -eq "Section titled: Parameters") {
        $parametersIndex = $i
        break
    }
}

$titles = $html.getElementsByTagName("h3")
$parameterInfos = $html.getElementsByClassName("parameterInfo")

$filteredTitles = @()
foreach ($title in $titles) {
    if ($title.id -notlike "*example*") {
        $filteredTitles += $title
    }
}

$data = @()
for ($i = $parametersIndex; $i -lt $filteredTitles.length; $i++) {
    $titleElement = $filteredTitles[$i]
    $titleText = $titleElement.innerText

    # Remove leading '-' if present
    $cleanTitle = $titleText.TrimStart('-')

    # Ensure there is a corresponding parameterInfo block
    if ($i -lt $parameterInfos.length) {
        $parameterInfoText = $parameterInfos[$i].innerText
    } else {
        $parameterInfoText = "No parameter info available"
    }

    # Store the cleaned title and parameter info in a custom object
    $data += [pscustomobject]@{
        Title = $cleanTitle
        ParameterInfo = $parameterInfoText
    }
}

#Remove last item from list
$finalItemIndexID = $data.count - 2
$trimmedData = $data[0..$finalItemIndexID]


$data | Export-Csv -Path $OutputFileName -NoTypeInformation

Write-Host "Data successfully scraped and saved to $OutputFilePath"
