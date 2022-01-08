# Andrew Sharrem
General Manager @ [National Fire & Security Ltd](https://www.nfs.nz/).

Developer & Curator of [NxOS](https://support.nfs.co.nz/menu/nxwitness/nxos-versions);
  Lightweight Ubuntu Distribution specifically built to run [NxWitness (by Networkoptix)](https://www.networkoptix.com/nx-witness/) as a Server & Client Appliance.

This public github hosts various files & scripts specific to NxOS, as well as some code that aids various projects I work on.
My personal favourite is [cascade_rc.xml](https://asharrem.github.io/cascade_rc.xml).
## Cascading Windows on Openbox WM
[Openbox](http://openbox.org/) is a stacking & tiling Window Manager. Tiling is generally achevied by Keybindings.
  [cascade_rc.xml](https://asharrem.github.io/cascade_rc.xml) is a keybind I wrote that cascades openbox client windows (per monitor).
  For a number of years I've been searching how I might "Cascade" windows, with most every reference saying it can't be done with openbox alone, and to use a "Tiling" application. Well...using a looping action/condition we can achieve a "cascade per monitor" keybind.

The nested loop structure is;
```
ForEach
  Move each Window to Top Left
  Lower
  ForEach
    Nudge All Windows
  End ForEach
End ForEach
```
The result is a bit like the first action of a "Card Shuffle", and the nested loops will "Cascade" client windows.

With a few other "actions" we are able to maintain "Focus" or include "minimized/iconified" client windows. Un-iconifying or maximizing minimized windows requires the iconified windows get "Focus", so currently I am unable to maintain focus of the original window in this instance.
