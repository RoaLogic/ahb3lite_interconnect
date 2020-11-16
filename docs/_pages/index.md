---
title: Roa Logic AHB-Lite Multilayer Switch Documentation
author: Roa Logic
permalink: /
---

# AHB-Lite Multilayer Switch

The Roa Logic *AHB-Lite Multi-layer Interconnect* is a fully parameterized High Performance, Low Latency Interconnect Fabric soft IP for AHB-Lite. It allows a virtually unlimited number of AHB-Lite bus masters and slaves to be connected without the need of bus arbitration to be implemented by the bus masters. Instead, slave side arbitration is implemented for each slave port within the core.

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

This release requires the ahb3lite package found here: [https://github.com/RoaLogic/ahb3lite_pkg][ahb3lite pkg]

[^1]: The number of bus masters and slaves is physically limited by the timing requirements of the design.

[GitHub Pages]:   https://roalogic.github.io/ahb3lite_interconnect/ "GitHub Pages Documentation"

[ahb3lite pkg]:   https://github.com/RoaLogic/ahb3lite_pkg "ahb3lite submodule"

[System Diagram]: {{site.baseurl}}{% link assets/img/ahb-lite-switch-sys.png %} "Example Interconnect System"

[HTML Datasheet]: {{site.baseurl}}{% link ahb3lite_interconnect_datasheet.md %} "AHB3Lite Interconnect Datasheet (HTML)"

[PDF Datasheet]:  {{site.baseurl}}{% link ahb3lite_interconnect_datasheet.pdf %} "AHB3Lite Interconnect Datasheet (PDF)"

[NC License]:     {{site.baseurl}}{% link _pages/license.md %} "Non-Commercial License"

[ReadMe]:         {{site.baseurl}}{% link readme.md %}
