; Documentation: https://docs.google.com/document/d/1hdxWs1B4XUBNSWsuO7dYCkg_6YBa4E0-jWKeLSXJ8yM/edit?usp=sharing

ListLines(false)

; Set SendMode to "Event". Solved a lot of problems with Send()'s in other games.
SendMode("Event")

; Show a tooltip to let the user know the script has been loaded
CoordMode("ToolTip", "Screen")
ToolTip("Loaded SkillChecks ver2.ahk successfully!", 5, 5)
SetTimer("delTool", -1000)

delTool() => ToolTip()

; Force single-instance behavior to ensure only one version of the script is running and to allow quick reloads
#SingleInstance force

; SetTitleMatchMode pre-set: no need to check for skill checks if we're not tabbed into the game
SetTitleMatchMode(2)

; CoordMode pre-set: All GetPixel checks will be done relative to the active window's client area to ensure
; compatibility of the script no matter if the game is in fullscreen or windowed and independent of
; this client area's resolution or size
CoordMode("Pixel", "Client")

; Declare some functions to help with pixel color analysis
; Simple hex lookup table to return a hex number's decimal equivalent
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

; These return the substring of a given color converted to RBG values
getR(color) => lookupHex(SubStr(color, 3, 1)) * 16 + lookupHex(SubStr(color, 4, 1))
getG(color) => lookupHex(SubStr(color, 5, 1)) * 16 + lookupHex(SubStr(color, 6, 1))
getB(color) => lookupHex(SubStr(color, 7, 1)) * 16 + lookupHex(SubStr(color, 8, 1))

; This returns an array of the previous functions' results
getRGB(color) => [getR(color), getG(color), getB(color)]

; This checks if the found color can be considered "white enough" for our purposes
; The color is considered "white enough" if all components of the RBG color are greater than 253, which is only 2 shades below full white
; Expects an array of length 3; will 100% error if this is not the case
compareWhite(colorArray) => (colorArray[1] > 253 && colorArray[2] > 253 && colorArray[3] > 253) ? true : false

; This checks if the found color can be considered "red enough" for our purposes
; The color is considered "red enough" if the R component is greater than 160, and the G and B components are less than 150
; Why so much "margin of error" up and down the color spectrum? Should hopefully prevent issues with fast movement and resulting color mixing... or blurring, rather
; Expects an array of length 3; will 100% error if this is not the case
compareRed(colorArray) => (colorArray[1] > 160 && colorArray[2] < 150 && colorArray[3] < 150) ? true : false

; An active skill check was found and has been handled. This function will reset the flag 'skillCheckIsActive' and allow for
; another skill check to be detected and handled, rinse and repeat
resetActive() => skillCheckIsActive := false

; Defining some important constants for later:
; - the radius of the circle of which we're testing the coordinates (check documentation: https://docs.google.com/document/d/1hdxWs1B4XUBNSWsuO7dYCkg_6YBa4E0-jWKeLSXJ8yM/edit#heading=h.rtxa90h3ust7)
; - ...pi
; - the string for the Send() function called once we're ready to do so (the key we're sending)
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

    ; Start at 0, then work CCW and test each pixel's color
    ; If nothing was found, restart the entire process
    while (true)
    {
        if (WinActive("ahk_exe DeadByDaylight-Win64-Shipping.exe"))
        {
            WinGetClientPos(, , clientAreaW, clientAreaH, "ahk_exe DeadByDaylight-Win64-Shipping.exe")

            if (!overrideRadius)
            {
                if (clientAreaW = 0 || clientAreaH = 0)
                {
                    ; Weird stuff going on with the client area size, so go back to the start of the while loop
                    ; until we get results that... make sense
                    continue
                }

                skillCheckRingPixelsW := (64 / 1920) * clientAreaW
                skillCheckRingPixelsH := (63 / 1080) * clientAreaH

                ; This should literally NEVER be true. If it is, alert the authorities.
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
                        ; Found the Great success zone -> there's an active skill check, so store where it is,
                        ; set a timer to reset the skillCheckIsActive variable after 1.8 seconds
                        ; Then reset j and break out of the while loop
                        skillCheckIsActive := true
                        foundX := x
                        foundY := y
                        SetTimer("resetActive", -2500)

                        j := 120

                        break
                    }

                    ; Increment j by 4 (pseudo-)angle units
                    j += 4
                }
            }

            if (skillCheckIsActive)
            {
                color := PixelGetColor(foundX, foundY)
                color := getRGB(color)

                if (compareRed(color))
                {
                    ; Send two inputs, some time apart, in case the first one fails for some reason so at
                    ; least the skill check gets saved and completed Well instead of Great... which is still better than not at all
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