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
	Remove-Module [p]ester
	Import-Module "$PSScriptRoot\tools\Pester\tools\Pester.psm1" -Force -Global # See https://github.com/pester/Pester/issues/576

	$testResults = "lalala";
	if ( $isCiServer ){
		$testResults = Invoke-Pester "$srcFolder" -OutputFile "$artifactFolder\pester.xml"  -OutputFormat NUnitXml -PassThru
	} else {
		$testResults = Invoke-Pester "$srcFolder" -PassThru
	}

	if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

## Helper Functions ##########

function Coalesce($a, $b) { if ($a -ne $null) { $a } else { $b } }