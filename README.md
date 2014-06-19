thredds-tpac
============

This is the code our colleagues from TasPAC use to access and analyse data in THREDDS (TasPAC is the Tasmanian version of the ANUS-F)

```{r, eval = F}
# init
require("makeProject")
setwd("..")
makeProject(name = "thredds", path = getwd(), force = TRUE,
  author = "ivanhanigan", email = "ivan.hanigan@gmail.com")
setwd('thredds')
dir()
```
