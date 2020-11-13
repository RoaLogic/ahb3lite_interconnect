---
title: Roa Logic AHB-Lite Multilayer Switch Documentation
author: Roa Logic
permalink: /
---

# AHB-Lite Multilayer Switch

The *Roa Logic AHB-Lite Multi-layer Interconnect* is a fully parameterized High Performance, Low Latency Interconnect Fabric soft IP for AHB-Lite. It allows a virtually unlimited number of AHB-Lite Bus Masters and Slaves to be connected without the need of bus arbitration to be implemented by the Bus Masters. Instead, Slave Side Arbitration is implemented for each Slave Port within the core.

The Multi-layer Interconnect supports Priority and Round-Robin based arbitration when multiple Bus Masters request access to the same Slave Port. Arbitration typically completes within 1 clock cycle

![System Diagram][]

## Features

- AMBA AHB-Lite Compatible
- Fully parameterized
- Unlimited number of Bus Masters and Slaves[^1]
- Slave side arbitration
- Priority and Round-Robin based arbitration
- Slave Port address decoding
- Slave Masking to increase system performance - ***New in v1.2***
- Error assertion when no slave correctly addressed - ***New in v1.3***

## Interfaces

- AHB-Lite Master & Slave Interfaces

## Documentation

- Datasheet: [HTML Format][HTML Datasheet]
- Datasheet: [PDF Format][PDF Datasheet]
- About this Documentation: [ReadMe](/readme)


## License

Released under the RoaLogic [Non-Commercial License][NC License]

## Dependencies

This release requires the ahb3lite package found here: [https://github.com/RoaLogic/ahb3lite_pkg][ahb3lite pkg]

[^1]: The number of Bus Masters and Slaves is physically limited by the timing requirements of the design.

[GitHub Pages]:   https://roalogic.github.io/ahb3lite_interconnect/ "GitHub Pages Documentation"

[ahb3lite pkg]:   https://github.com/RoaLogic/ahb3lite_pkg "ahb3lite submodule"

[System Diagram]: {% link /assets/img/ahb-lite-switch-sys.png %} "Example Interconnect System"

[HTML Datasheet]: {% link ahb3lite_interconnect_datasheet.md %} "AHB3Lite Interconnect Datasheet (HTML)"

[PDF Datasheet]:  {% link ahb3lite_interconnect_datasheet.pdf %} "AHB3Lite Interconnect Datasheet (PDF)"

[NC License]:     {% link _pages/license.md %} "Non-Commercial License"

