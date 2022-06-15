![image](https://user-images.githubusercontent.com/53089531/173842728-4790a738-5ac7-4383-b151-a57a44aef994.png)

# Glaci-Dice

GLACIDICE is a model based on [NUNAIT](https://github.com/angelrodes/NUNAIT) that simulates the cosmonuclide accumulation on the faces of dice-shaped boulders that are shielded and rotated during glaciations.

>[*Glaciers do play dice with the boulders*](https://en.wiktionary.org/wiki/God_does_not_play_dice_with_the_universe)

Ángel Rodés, 2022  
[www.angelrodes.com](www.angelrodes.com)

## How it works

### Input 

When you run the script ```GlaciDice_v1.m```, a dialog will ask you about the parameters of the simulations:

- Boulder size: range for side lengths of the diced-boulders, in cm.
- Last deglaciation: range of ages (in years) when the area was deglaciated. This will define when the boulders were exposed to cosmic radiation or shielded under the glacier, based on the reference δ<sup>18</sup>O curve.
- Ice depth: the thickness of ice during glaciations in metres. This model considers some muon production under the ice.
- Nuclide mass: 3 for <sup>3</sup>He, 10 for <sup>10</sup>Be, etc.
- Number of dices to roll: number of simulations. Each model will calculate the accumulation through time on one face of a single boulder.

![image](https://user-images.githubusercontent.com/53089531/173845895-d71de27a-66a2-4f9b-9982-d5cecf9a91c3.png)

### Output

The script outputs three graphs:

- Top-left: a graph showing the history of the boulders in relation to the δ<sup>18</sup>O curve.
- Bottom-left: a graph showing when each dice have been randomly rolled (black dots).
- Right: a graph showing the relation between the exhumation age of a boulder (first exposure, x-axis) and the expected apparent surface exposure age (ASEA, y-axis). The red dots correspond to ASEAs from the center of the current top face of the boulder, magenta dots correspond to ASEAs from the current sides, and red dots correspond to ASEAs from the bottom of the boulder.

![image](https://user-images.githubusercontent.com/53089531/173847177-21ab72d9-0d57-4e9b-8e59-a5953dfceb78.png)

## Under the hood

The production rates and exposure-burial model are based on [NUNAIT](https://github.com/angelrodes/NUNAIT):

>Rodés, Á. (2021) The NUNAtak Ice Thinning (NUNAIT) Calculator for Cosmonuclide Elevation Profiles. *Geosciences* 11, no. 9: 362. doi:[10.3390/geosciences11090362](https://doi.org/10.3390/geosciences11090362)

The shielding of the side and bottom faces of the dices are approximated using [this approach](https://github.com/angelrodes/Shielding_of_dice-shaped_boulders). I generated synthetic cubes and calculated the shelf-shielding correction at the center of sides and bottom faces using Balco (2014):

> Greg Balco (2014) Simple computer code for estimating cosmic-ray shielding by oddly shaped objects. [Quaternary Geochronology, Volume 22, Pages 175-182.](https://doi.org/10.1016/j.quageo.2013.12.002)

No boulder erosion or weathering is considered yet. Therefore, the modeled exhumation ages (the times when the boulder is first exposed to the cosmic radiation) should be considered as minimum ages.

## Model behaviour 

With the example given in the figures above (~2m boulders in an area that was deglaciated after the Younger Dryas) the <sup>10</sup>Be apparent surface exposure age (<sup>10</sup>Be ASEA) at the top of the boulder underestimates exhumation ages from previous interglacials by a factor of ~10. For example, a boulder exhumed 300 ka ago will yield top <sup>10</sup>Be ASEAs of ~30 ka. This is the combined effect of the shielding by the glacier during glaciations and the self-shielding during previous interglacials, as the current top face of this boulder was randomly exposed at a top, side, or bottom position.

Also, according to the example shown, the boulders that have survived more than 4 or 5 glaciations (>400 ka) seem to show similar <sup>10</sup>Be ASEAs independently of the face sampled (top, side, or bottom). Therefore, the difference in top, side and bottom <sup>10</sup>Be ASEAs could give us a hint on how many glaciations a boulder has been rolling around.
