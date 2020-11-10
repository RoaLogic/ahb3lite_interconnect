![Roa Logic Hdr][]

# AHB-Lite Multilayer Switch

The Roa Logic AHB-Lite Multi-layer Interconnect is a fully parameterized High Performance, Low Latency Interconnect Fabric soft IP for AHB-Lite. It allows a virtually unlimited number of AHB-Lite Bus Masters and Slaves to be connected without the need of bus arbitration to be implemented by the Bus Masters. Instead, Slave Side Arbitration is implemented for each Slave Port within the core.

The Multi-layer Interconnect supports Priority and Round-Robin based arbitration when multiple Bus Masters request access to the same Slave Port. Typically arbitration completes within 1 clock cycle

![System Diagram][]

## Features

- AMBA AHB-Lite Compatible
- Fully parameterized
- Unlimited number of Bus Masters and Slaves<sup>1</sup>
- Slave side arbitration
- Priority and Round-Robin based arbitration
- Slave Port address decoding
- Slave Masking to increase system performance - ***New in v1.2***
- Error assertion when no slave correctly addressed - ***New in v1.3***

## Interfaces

- AHB-Lite Master & Slave Interfaces

## Documentation

- [GitHub Pages Documentation][GitHub Pages]
- [HTML Datasheet (via GitHub Pages)][HTML Datasheet]
- [Markdown Datasheet][MD Datasheet]
- [PDF Datasheet][PDF Datasheet]

## License

Released under the Roa Logic [Non-Commercial License][NC License]

## Dependencies

This release requires the ahb3lite package found here: [`https://github.com/RoaLogic/ahb3lite_pkg`][ahb3lite pkg]

- - -

<sup>1</sup>The number of Bus Masters and Slaves is physically limited by the timing requirements of the design.

[Roa Logic Hdr]:  /docs/assets/img/RoaLogicHeader.png

[GitHub Pages]:   https://roalogic.github.io/ahb3lite_interconnect "GitHub Pages Documentation"

[HTML Datasheet]: https://roalogic.github.io/ahb3lite_interconnect/ahb3lite_interconnect_datasheet.html "HTML Datasheet"

[MD Datasheet]:   /docs/ahb3lite_interconnect_datasheet.md "Markdown Datasheet"

[PDF Datasheet]:  /docs/ahb3lite_interconnect_datasheet.pdf "PDF Datasheet"

[System Diagram]: /docs/assets/img/ahb-lite-switch-sys.png "Example Interconnect System"

[NC License]:     LICENSE.md "Non-Commercial License"

[ahb3lite pkg]:   https://github.com/RoaLogic/ahb3lite_pkg "ahb3lite submodule" 
