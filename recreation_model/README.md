# BioDT Cultural Ecosystem Services pDT - Recreation Potential
## Overview
This is the Recreation Potential model, which is currently targeted at the Cairngorms National Park only.
From raster input files (e.g. of walking paths) and scores for features in those files (e.g. gentle paths are preferred by some, steep paths by others) it produces a raster map of the Cairngorms National Park showing areas with high recreation potential for a chosen persona.

Full notes/documentation will follow.

## Input data structure
The `data` folder shows the structure that the input data requires.
Raster input files must have a file extension (e.g. {{ some name }}.tif) and scores must be {{ some name }}.csv so they can be matched against the correct raster file.
