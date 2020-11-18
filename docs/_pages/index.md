---
title: Documentation
permalink: /
---

# {{site.title}}

The Roa Logic *AHB-Lite Multi-layer Interconnect Switch* is a fully parameterized High Performance, Low Latency Interconnect Fabric soft IP for AHB-Lite. It allows a virtually unlimited number of AHB-Lite bus masters and slaves to be connected without the need of bus arbitration to be implemented by the bus masters. Instead, slave side arbitration is implemented for each slave port within the core.

The Multi-layer Interconnect supports priority and round-robin based arbitration when multiple bus masters request access to the same slave port. Arbitration typically completes within 1 clock cycle

![System Diagram][]

## Features

- AMBA AHB-Lite compatible
- Fully parameterized
- Unlimited number of bus masters and slaves[^1]
- Slave side arbitration
- Priority and round-robin based arbitration
- Slave port address decoding
- Slave masking to increase system performance - ***New in v1.2***
- Error assertion when no slave correctly addressed - ***New in v1.3***

## Interfaces

- AHB-Lite master & slave interfaces

## Documentation

- Datasheet: [HTML Format][HTML Datasheet]
- Datasheet: [PDF Format][PDF Datasheet]
- About this documentation: [ReadMe][]

## License

Released under the RoaLogic [Non-Commercial License][NC License]

## Dependencies

This release requires the Roa Logic [ahb3lite package][ahb3lite pkg]

[^1]: The number of bus masters and slaves is physically limited by the timing requirements of the design.

[System Diagram]: {{site.baseurl}}{% link assets/img/ahb-lite-switch-sys.png %}
                  "Example Interconnect System"

[HTML Datasheet]: {{site.baseurl}}/{{ site.github.repository_name | append: "_datasheet.html" }}
                  "AHB3Lite Interconnect Datasheet (HTML)"

[PDF Datasheet]:  {{site.baseurl}}/{{site.github.repository_name | append: "_datasheet.pdf"}} 
                  "AHB3Lite Interconnect Datasheet (PDF)"

[NC License]:     {{site.baseurl}}{% link _pages/license.md %} 
                  "Non-Commercial License"

[ReadMe]:         {{site.baseurl}}{% link readme.md %}


[GitHub Pages]:   {{site.github.url}} "GitHub Pages Documentation"

[ahb3lite pkg]:   {{site.github.owner_url}}/ahb3lite_pkg "ahb3lite submodule"
