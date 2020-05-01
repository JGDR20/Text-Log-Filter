# Search all matching files (e.g. *.log) in a directory for a specified string
# Add the search function and matched lines to an output file in the directory
# Display the number of results found for each file in the console

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True)][string]$Dir, # Directory to search
	[Parameter(Mandatory=$True)][string]$FilePattern, # Pattern for filenames
	[Parameter(Mandatory=$True)][string]$Pattern, # Text pattern to search for
	[Parameter(Mandatory=$True)][string]$Output # Output filename
)

## Functions

# State-Query | Add the search function text to the output file for reference
Function State-Query ([string]$File, [string]$Pattern, [string]$OutputPath, [string]$Dir) {
	Add-Content -Path $OutputPath -Value "(Select-String -Path $File -Pattern '$Pattern')"
}

# Search-Lines | Search all lines in the input file for the text pattern, count
# matches and add line content to the output file
Function Search-Lines ([string]$File, [string]$Pattern, [string]$OutputPath) {
	# Add bank line for ease of reading
	Add-Content -Path $OutputPath -NoNewline -Value `n
	# Initialise counter
	[int]$i = 0
	# Select lines in each input file that match the text pattern
	(Select-String -Path $File -Pattern $Pattern) |
		ForEach-Object {
			# For each line found, add the filename, line number and line
			# content to output file
			[string]$Line = $_.Filename + ":" + $_.LineNumber.ToString() + "||`t" + $_.Line
			Add-Content -Path $OutputPath -Value $Line
			# Increment counter
			$i++
		}
	# Display the number of matching lines found in the file
	Write-Output "$i lines in $File"
	# Add a separator line to the output file
	Add-Content -Path $OutputPath -Value "################`n"
}

# Search-Files | Indentify the files that match the filename pattern and pass
# each file (along with other parameters) to the State-Query and Search-Lines
# functions
Function Search-Files ([string]$Dir, [string]$FilePattern, [string]$Pattern, [string]$Output) {
	# Create an absolute output file path from the name and directory given
	$OutputPath = Join-Path -Path $Dir -ChildPath $Output
	# Identify the files that match the file pattern
	Get-ChildItem -Path $Dir -Filter $FilePattern -Recurse -File |
		ForEach-Object {
			# For each file found check if it is the Output file
			If ($_.Name -ne $Output) {
				# If it is not the Output file, make a splat of the parameters
				$splat = @{
					File = $_.FullName
					Pattern = $Pattern
					OutputPath = $OutputPath
				}
				# Pass splat to the State-Query and Search-Lines functions
				State-Query @splat
				Search-Lines @splat
			# If the file is the Output file, do nothing and move to next file
			}
		}
}

## Main

# Execute Search-Files function with provided parameters
Search-Files -Dir $Dir -FilePattern $FilePattern -Pattern $Pattern -Output $Output