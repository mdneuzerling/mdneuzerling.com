---
title: "Identifying Custom Australian Licence Plates"
author: ~
date: '2021-07-18'
slug: identifying-custom-australian-licence-plates
category: code
tags:
    - python
featured: "/img/featured/cars.webp"
output: hugodown::md_document
---

In case this saves anyone some time, here's a quick bit of regex and Python code for identifying if a given licence plate is standard or custom (personalised) in a given state.

I can't promise that this logic is correct or up to date. Some of the rules used are a bit more general than they need to be. I also tended to ignore rules before 1970. The rules come from:

-   <https://en.wikipedia.org/wiki/Vehicle_registration_plates_of_Australia>
-   <https://www.vicroads.vic.gov.au/registration/number-plates/general-issue-number-plates>

```python
import re

# Takes a pattern like xxxddd (for three letters followed by three numbers)
# and converts it to regex. Other characters are left as is in the regex
# pattern string. This is helpful for states like SA in which every modern
# licence plate begins with an "S".
def match_plate_pattern(plate, pattern):
    pattern = pattern.replace('x','[A-Za-z]').replace('d','[0-9]')
    return(re.fullmatch(pattern, plate))

licence_plate_patterns = {
    "VIC": ["dxxdxx", # current car 
            "xxxddd", # old car
            "dxdxx", # current motorcycle
            "xxddd"], # old motorcycle
    "NSW": ["xxddxx", # current car
            "xxxddx", # old car
            "xxxdd"], # motorcycles
    "QLD": ["dddxxx", # current car
            "dddxxd", # future car
            "dddxx"], # motorcycles
    "SA": ["Sdddxxx", # current car
           "dddxxx", # old car
           "Sddxxx", # current motorcycles
           "ddxxx"], # old motorcycles
    "WA": ["1xxxddd", # current style plates
            "xxxddd", # old style plates before 1978
            "dxxddd", # old style plates 1978--1997
            "1ddxxx"], # current motorcycles (1997 onwards)]
    "TAS": ["xddxx", # current style plates
            "xxdddd", # old style plates 1970--2008
            "xxxddd", # old style plates 1954--1970
            "xxddd", # motorcycles
            "xdddx"], # motorcycles
    "ACT": ["xxxddx", # current style plates
            "xxxddd", # future style plates
            "xdddd"], # motorcycles
    "NT": ["xxddxx", # current style plates
           "dddddd", # future style plates
           "xdddd", # current motorcycles
           "ddddd"] # old motorcycles 1979--2011
}
    
def plate_type(plate, state):

    # remove anything that isn't a letter or number
    plate = re.sub(r'[\W_]+', '', str(plate))

    plate_matches = [match_plate_pattern(plate, pattern) for pattern 
                     in licence_plate_patterns[state]]

    if plate == "": 
        return("no_plate")

    if any(plate_matches):
        return("standard_plate")
    
    return("custom_plate")
```

And some Victorian examples:

```python
plate_type("ABC-123", "VIC")
#> 'standard_plate'
plate_type("XY123", "VIC")
#> 'standard_plate'
plate_type("1AB-2CD", "VIC")
#> 'standard_plate'
plate_type("HOTROD", "VIC")
#> 'custom_plate'</code></pre>
```

------------------------------------------------------------------------

[The image at the top of this page is in the public domain.](https://unsplash.com/photos/Jk3-Uhdwjcs)
