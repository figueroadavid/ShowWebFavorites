[cmdletbinding()]
param(
    [parameter(ValueFromPipelineByPropertyName)]
    [ValidateScript({
        Test-Path -path (Resolve-path -path $_)
    })]
    [string]$ConfigFile = '.\Show-WebFavorites.xml'
)

$ConfigFilePath = (Resolve-Path -Path $ConfigFile ).Path


$xml = [xml]::new()
$xml.Load($ConfigFilePath)

$BrowserHash = @{}

$BrowserList = Select-XML -Xml $xml -XPath '//browser' | Select-Object -ExpandProperty node |
    ForEach-Object {
        $Node = $_
        $WorkingHash = @{
            'path'              = $node.path
            'workingdirectory'  = $node.workingdirectory
        }
        $BrowserHash.Add( $Node.name, $WorkingHash.Clone() )
        $WorkingHash.Clear()
    }

$GetBrowserInfo = {
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$BrowserName
    )

    $SelectParams = @{
        XML = $xml
        XPath = '//browser'
    }
    $BrowserInfo = Select-XML @SelectParams | Select-Object -ExpandProperty node
}

$LaunchFavorite = {
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$FavoriteName

        [parameter(ValueFromPipelineByPropertyName)]
        [switch]$UseIncognito
    )
    $FavoriteSelectParams = @{
        xml = $xml
        XPath = '//favorite[name="{0}"]' -f $FavoriteName
    }
    $Favorite = Select-XML @SelectParams | Select-Object -ExpandProperty node
    $BrowserName = $Favorite.prefbrowser

    $BrowserSelectParams = @{
        xml = $xml
        XPath = '//browser[@name="{0}"]' -f $BrowserName
    }
    $BrowserInfo = Select-XML $BrowserSelectParams | Select-Object -ExpandProperty node

    if ($UseIncognito) {
        $ArgList = '{0} {1}' -f $BrowserInfo.incognito, $favorite.url
    }
    else {
        $ArgList = $favorite.url
    }

    $ProcessStartInfo                   = [system.diagnostics.ProcessStartInfo]::new()
    $ProcessStartInfo.FileName          = $BrowserInfo.path
    $ProcessStartInfo.workingdirectory  = $BrowserInfo.workingdirectory
    $ProcessStartInfo.UseShellExecute   = $false
    $ProcessStartInfo.Arguments         = $ArgList

}
