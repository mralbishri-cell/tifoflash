Add-Type -AssemblyName System.Drawing

function Resize-ImageFile($srcPath, $destPath, $targetWidth, $targetHeight) {
    $oldImg = [System.Drawing.Image]::FromFile($srcPath)
    $newImg = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($newImg)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($oldImg, 0, 0, $targetWidth, $targetHeight)
    
    $oldImg.Dispose()
    $newImg.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $newImg.Dispose()
    $graphics.Dispose()
}

$src1 = "C:\Users\albis\.gemini\antigravity-ide\brain\46bf956a-e8ed-4eb8-af49-689bca4e2703\appstore_screenshot_1_1788015118754.jpg"
$src2 = "C:\Users\albis\.gemini\antigravity-ide\brain\46bf956a-e8ed-4eb8-af49-689bca4e2703\appstore_screenshot_2_1788015138287.jpg"

$dest1_proj = "c:\tifoflash\screenshots\appstore_screenshot_1.jpg"
$dest1_desk = "$env:USERPROFILE\Desktop\TifoFlash_Screenshots\appstore_screenshot_1.jpg"

$dest2_proj = "c:\tifoflash\screenshots\appstore_screenshot_2.jpg"
$dest2_desk = "$env:USERPROFILE\Desktop\TifoFlash_Screenshots\appstore_screenshot_2.jpg"

Resize-ImageFile $src1 $dest1_proj 1284 2778
Resize-ImageFile $src1 $dest1_desk 1284 2778

Resize-ImageFile $src2 $dest2_proj 1284 2778
Resize-ImageFile $src2 $dest2_desk 1284 2778

Write-Host "RESIZED_EXACTLY_TO_1284x2778"
