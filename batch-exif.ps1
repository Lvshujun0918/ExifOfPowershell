param(
    [string]$dir = (Get-Location)
)

Add-Type -AssemblyName System.Drawing

$exiftool = ".\exiftool.exe"
if (-not (Get-Command $exiftool -ErrorAction SilentlyContinue)) {
    Write-Host "请先将 exiftool.exe 放在本目录或加入环境变量"
    exit 1
}

$pattern = '(\d{4})-(\d{2})-(\d{2})_(\d{6})\.(jpg|png)$'

Get-ChildItem -Path $dir | ForEach-Object {
    $file = $_.FullName
    $name = $_.Name

    if ($name -match $pattern) {
        $year = $matches[1]
        $month = $matches[2]
        $day = $matches[3]
        $time = $matches[4]
        $hour = $time.Substring(0,2)
        $minute = $time.Substring(2,2)
        $second = $time.Substring(4,2)

        $datetime = "{0}:{1}:{2} {3}:{4}:{5}" -f $year, $month, $day, $hour, $minute, $second

        # 读取前4个字节判断格式
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $isPng = ($bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47)

        $baseName = $_.BaseName
        $outputJpg = $_.DirectoryName + "\exif\" + $baseName + "_exif.jpg"

        if ($isPng) {
            # 转换为JPG
            $img = [System.Drawing.Image]::FromFile($file)
            $jpgPath = $_.DirectoryName + "\" + $baseName + "_converted.jpg"
            $img.Save($jpgPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
            $img.Dispose()
            # 用转换后的JPG写入EXIF
            & $exiftool -DateTimeOriginal="$datetime" -overwrite_original -out $outputJpg $jpgPath
            # Remove-Item $jpgPath
            Write-Host "PNG已转JPG并写入EXIF：$file -> $outputJpg，EXIF时间：$datetime"
        } else {
            # 直接写入EXIF
            & $exiftool -DateTimeOriginal="$datetime" -overwrite_original -out $outputJpg $file
            Write-Host "JPG已写入EXIF：$file -> $outputJpg，EXIF时间：$datetime"
        }
    }
}