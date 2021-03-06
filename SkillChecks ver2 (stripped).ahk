/*
    Comments removed using regex pattern    (.*; .*\n*\r*\n*)
    Made using https://regexr.com/ because I'm horrible at regex patterns :)
*/

ListLines(false)

SendMode("Event")

CoordMode("ToolTip", "Screen")
ToolTip("Loaded SkillChecks ver2.ahk successfully!", 5, 5)
SetTimer("delTool", -1000)

delTool() => ToolTip()

#SingleInstance force

SetTitleMatchMode(2)

CoordMode("Pixel", "Client")

lookupHex(c)
{
    switch (c)
    {
        case 0, 1, 2, 3, 4, 5, 6, 7, 8, 9:
            return c
        case "A":
            return 10
        case "B":
            return 11
        case "C":
            return 12
        case "D":
            return 13
        case "E":
            return 14
        case "F":
            return 15
        default:
            return
    }
}

getR(color) => lookupHex(SubStr(color, 3, 1)) * 16 + lookupHex(SubStr(color, 4, 1))
getG(color) => lookupHex(SubStr(color, 5, 1)) * 16 + lookupHex(SubStr(color, 6, 1))
getB(color) => lookupHex(SubStr(color, 7, 1)) * 16 + lookupHex(SubStr(color, 8, 1))

getRGB(color) => [getR(color), getG(color), getB(color)]

compareWhite(colorArray) => (colorArray[1] > 253 && colorArray[2] > 253 && colorArray[3] > 253) ? true : false

compareRed(colorArray) => (colorArray[1] > 160 && colorArray[2] < 150 && colorArray[3] < 150) ? true : false

resetActive() => skillCheckIsActive := false

radius := 0
overrideRadius := false
pi := 4 * atan(1)
sendString := "XButton2"

warnedAboutWeirdResults := false

foundX := 0
foundY := 0
skillCheckIsActive := false

function()
{
    global

    while (true)
    {
        if (WinActive("ahk_exe DeadByDaylight-Win64-Shipping.exe"))
        {
            WinGetClientPos(, , clientAreaW, clientAreaH, "ahk_exe DeadByDaylight-Win64-Shipping.exe")

            if (!overrideRadius)
            {
                if (clientAreaW = 0 || clientAreaH = 0)
                {
                    continue
                }

                skillCheckRingPixelsW := (64 / 1920) * clientAreaW
                skillCheckRingPixelsH := (63 / 1080) * clientAreaH

                if (Abs(1 - (skillCheckRingPixelsW / skillCheckRingPixelsH)) > 0.025)
                {
                    if (!warnedAboutWeirdResults)
                    {
                        ListLines(true)
                        log := "Logged message:`n" "Unexpected results for the radius: w = " . skillCheckRingPixelsW . ", h = " . skillCheckRingPixelsH
                        . "`nThe aspect ratio of the client area is " . (clientAreaW / clientAreaW) . "."
                        . "`n16:9 is " . Round(16/9, 2) . ", 4:3 is " Round(4/3, 2) "."
                        ListLines(false)

                        MsgBox("Either a calculation has gone terribly wrong or the game is running at a really weird aspect ratio or resolution.`nOpting to use the result calculated based on client area height as the numbers here tend to be smaller.`n`nThe script might not work correctly, if at all!`n`nThis warning will not be shown again until the script is reloaded.", "Warning", 16)
                        warnedAboutWeirdResults := true
                    }
                }
            
                radius := skillCheckRingPixelsH
                overrideRadius := true
            }

            j := 120

            if (!skillCheckIsActive)
            {
                while (j < 360)
                {
                    x := clientAreaW / 2 + radius * cos(j * pi / 180)
                    y := clientAreaH / 2 + radius * sin(j * pi / 180)

                    color := PixelGetColor(x, y)
                    color := getRGB(color)
                    if (compareWhite(color))
                    {
                        ListLines(true)
                        skillCheckIsActive := true
                        foundX := x
                        foundY := y
                        SetTimer("resetActive", -2500)

                        j := 120

                        break
                    }

                    j += 4
                }
            }

            if (skillCheckIsActive)
            {
                color := PixelGetColor(foundX, foundY)
                color := getRGB(color)

                if (compareRed(color))
                {
                    SendInput("{" . sendString . "}")
                    SendPlay("{" . sendString . "}")
                    SendEvent("{" . sendString . "}")
                    skillCheckIsActive := false
                }
            }
            ListLines(false)
        }
    }
}

function()