//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @member projectId The id of the project.
 * @member textColor The hex color of the text.
 * @member bgColor The hex color of the background.
 * @member bgColorDark The hex color of the background in dark mode.
 */
struct Theme {
    uint256 projectId;
    string textColor;
    string bgColor;
    string bgColorDark;
}
