$currentDirectory = $PWD.Path
$toolchainpath = "$currentDirectory\winlibs-x86_64-mcf-seh-gcc-13.2.0-mingw-w64ucrt-11.0.1-r2\mingw64\bin"
$logfile = "runtime.txt"

if ((Test-Path -Path "cppcheck" -PathType Container)) {
	rm -r -fo .\cppcheck\
}

if ((Test-Path -Path "winlibs-x86_64-mcf-seh-gcc-13.2.0-mingw-w64ucrt-11.0.1-r2" -PathType Container)) {
	rm -r -fo .\winlibs-x86_64-mcf-seh-gcc-13.2.0-mingw-w64ucrt-11.0.1-r2\
}

echo "[i] extract cppcheck:" > "$currentDirectory\$logfile"
Invoke-WebRequest -Uri https://github.com/danmar/cppcheck/archive/refs/tags/2.12.1.zip -OutFile "$currentDirectory\cppcheck.zip"
Measure-Command {Expand-Archive "cppcheck.zip" | Out-Default } | Tee-Object -FilePath "$currentDirectory\$logfile" -Append

if (-not (Test-Path -Path $toolchainpath -PathType Container)) {
	# Define the URL of the file you want to download
	$url = "https://github.com/brechtsanders/winlibs_mingw/releases/download/13.2.0mcf-16.0.6-11.0.1-ucrt-r2/winlibs-x86_64-mcf-seh-gcc-13.2.0-mingw-w64ucrt-11.0.1-r2.zip"

	# Define the local path where you want to save the downloaded file
	$localPath = "$currentDirectory\winlibs-x86_64-mcf-seh-gcc-13.2.0-mingw-w64ucrt-11.0.1-r2.zip"

	# Create a WebClient object
	$webClient = New-Object System.Net.WebClient

	# Download the file synchronously
	try {
		$webClient.DownloadFile($url, $localPath)
		Write-Host "Download completed successfully."
	} catch {
		Write-Host "Download failed with error: $_"
	} finally {
		$webClient.Dispose()  # Dispose of the WebClient object
	}
	# wget https://github.com/brechtsanders/winlibs_mingw/releases/download/13.2.0mcf-16.0.6-11.0.1-ucrt-r2/winlibs-x86_64-mcf-seh-gcc-13.2.0-mingw-w64ucrt-11.0.1-r2.zip
	echo "[i] extract toolchain:" >> "$currentDirectory\$logfile"
	Measure-Command { Expand-Archive "winlibs-x86_64-mcf-seh-gcc-13.2.0-mingw-w64ucrt-11.0.1-r2.zip" | Out-Default } | Tee-Object -FilePath "$currentDirectory\$logfile" -Append
} else {
	Write-Host "The toolchain is already there"
}

$env:path="$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\Wbem;$env:SystemRoot\System32\WindowsPowerShell\v1.0\"
$env:path += ";$toolchainpath"

pushd "cppcheck\cppcheck-2.12.1"
mkdir buildbench
pushd buildbench
echo "[i] cmake prepare cppcheck:" >> "$currentDirectory\$logfile"
Measure-Command { cmake .. -G "MinGW Makefiles" | Out-Default } | Tee-Object -FilePath "$currentDirectory\$logfile" -Append
echo "[i] build cppcheck:" >> "$currentDirectory\$logfile"
Measure-Command { cmake --build . -j | Out-Default } | Tee-Object -FilePath "$currentDirectory\$logfile" -Append
popd
popd
cat "$currentDirectory\$logfile"