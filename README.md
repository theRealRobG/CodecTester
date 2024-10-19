# CodecTester

This is a very basic application that allows the user to query how AVPlayer may or may not understand various codecs
strings. The user is able to input a "fallback" codecs string and a "preferred" codecs string. When the "Test" button
is slected, we start a player and provide it a custom manifest that uses the user provided codecs to define the
renditions, while pushing the player towards the "preferred" by providing it a higher "SCORE" attribute.

This essentially hinges on the following manifest:
```
#EXTM3U

#EXT-X-STREAM-INF:BANDWIDTH=573600,CODECS="\(fallbackCodecs)",SCORE=0.5
customcodec://example.com/fallback.m3u8

#EXT-X-STREAM-INF:BANDWIDTH=573600,CODECS="\(preferredCodecs)",SCORE=1.0
customcodec://example.com/preferred.m3u8
``` 

We purposefully have everything stripped from this manifest such that selection criteria has been reduced to the
minimum. The `SCORE` is to drive the player towards selecting the "preferred.m3u8" which *SHOULD* happen if the provided
`CODECS` is supported. Once one of the renditions is selected we're informed via `AVAssetResourceLoaderDelegate`, we
capture the result, and then discard the player. The result is then printed out onto the view for the user. 
