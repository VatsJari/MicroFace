# 02_Fiji_Pre-processing_Macro

**Macro:** [`../../1_Toolbox/Fiji/Pre_Processing.ijm`](../../1_Toolbox/Fiji/Pre_Processing.ijm)

The macro lives in `1_Toolbox` so there is a single authoritative copy rather
than one per folder. Requires Fiji 1.53 or later.

In Fiji: `Plugins > Macros > Run...`, select the macro, then give it
`01_Raw_Images` as input and `03_Pre_processed_Images` as output. It runs in
batch mode over every file.

Three operations per image: contrast normalisation
(`saturated=1.0 normalize`), rolling-ball background subtraction
(`rolling=50`), and subtraction of a radius-20 median-filtered copy.

The median subtraction is the step that decides whether step 4 works. A
radius-20 median is a local background estimate well above the width of a
microglial process, so subtracting it removes diffuse haze while leaving
ramifications intact. Skip it and adaptive thresholding fuses neighbouring
process fields, worst where cells are densest, which is the peri-implant zone.

Full reasoning: [tutorial step 2](../README.md#step-2-pre-processing-in-fiji).

**Next:** [step 3](../03_Pre_processed_Images/) · [tutorial](../README.md)
