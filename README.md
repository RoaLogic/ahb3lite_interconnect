![Roa Logic Hdr][]

# AHB-Lite Multi-layer Interconnect Switch

The Roa Logic *AHB-Lite Multi-layer Interconnect Switch* is a fully parameterized High Performance, Low Latency Interconnect Fabric soft IP for AHB-Lite. It allows a virtually unlimited number of AHB-Lite bus masters and slaves to be connected without the need of bus arbitration to be implemented by the bus masters. Instead, slave side arbitration is implemented for each slave port within the core.

The Interconnect supports priority and round-robin based arbitration when multiple bus masters request access to the same slave port. Arbitration typically completes within 1 clock cycle

![System Diagram][]

## Features

- AMBA AHB-Lite compatible
- Fully parameterized
- Unlimited number of bus masters and slaves<sup>1</sup>
- Slave side arbitration
- Priority and round-robin based arbitration
- Slave port address decoding
- Slave masking to increase system performance - ***New in v1.2***
- Error assertion when no slave correctly addressed - ***New in v1.3***

## Interfaces

- AHB-Lite master & slave interfaces

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
