Properties {
	$ApiKey = Coalesce $Env:ApiKey ""
}

## Globals ###################

$script:gitVersion = {}
$isCiServer = $Env:TEAMCITY_VERSION -ne $null
$artifactFolder = "$PSScriptRoot\..\artifacts"
$srcFolder = "$PSScriptRoot\..\src"
$nugetExe = "$PSScriptRoot\tools\nuget\nuget.exe"

## Task ######################

Task Default -Depends Clean, RestoreTools, UnitTest
Task CiBuild -Depends Default

Task Clean {
	if ( Test-Path $artifactFolder ) {
		Remove-Item $artifactFolder -Recurse -Force
	}
	New-Item $artifactFolder -ItemType Directory | Out-Null
}

Task RestoreTools {
	Exec { & $nugetExe install packages.config -ExcludeVersion -OutputDirectory "$PSScriptRoot\tools" -Verbosity Detailed }
}

Task UnitTest {
	Write-Host "1"
	Remove-Module [p]ester
	Import-Module "$PSScriptRoot\tools\Pester\tools\Pester.psm1" -Force -Global # See https://github.com/pester/Pester/issues/576
	Write-Host "2"

	if ( $isCiServer ){
		Write-Host "hello CI"
		Invoke-Pester "$srcFolder" -OutputFile "$artifactFolder\pester.xml"  -OutputFormat NUnitXml
	} else {
		Write-Host "hello"
		Invoke-Pester "$srcFolder"
	}
}

## Helper Functions ##########

function Coalesce($a, $b) { if ($a -ne $null) { $a } else { $b } }