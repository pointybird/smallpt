# Crystal smallpt

This is a fairly direct port of Kevin Beason's [smallpt](http://www.kevinbeason.com/smallpt/) global illumination renderer into Crystal.

As with the original, the focus is not on readability, but rather having a fully functioning renderer in under 100 lines of code.

Usage:
```
crystal build smallpt.cr
./smallpt 100
```

where 100 is the number of samples per pixel (must be at least 4).

