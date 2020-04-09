# MEMR Rasmussen Memory Test - Version 2.2
```
; 
; MEMR Rasmussen memory test for CP/M2 on Altair.
; Version 2.2
;
; Copyright (C) 1980 Lifeboat Associates
;
; Reconstructed from memory image on April 9, 2020
; by Patrick A Linstruth (patrick@deltecent.com)
;
```

The MEMR Rasmussen memory test was developed at
Lifeboat Associates so that their customers could easily
check their memory system.

>The program performs a battery of tests to test memory under a variety of conditions.  If a test fails in any given memory location, that location will be displayed on the console along with the byte that should have been in memory and the actual value in both HEX and binary bits. This may be a further aid to find out what is wrong. If multiple errors are reported, the test will display a screen full of error reports, one to a line, and then wait for you to press a key to continue.  Until the screen if full of error reports, the test will continuously cycle.

The source code was reconstructed from the binary image of `MEMR.COM` distributed on the `lifeboat.dsk` CP/M image downloaded from [DERAMP.COM](https://deramp.com/downloads/altair/software/8_inch_floppy/CPM/CPM%202.2/Lifeboat%20CPM/).
