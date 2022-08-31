# QRGen
Swift CLI tool to generate QR codes (PNG and SVG) from data or text

## Usage

```
USAGE: QRGen [OPTIONS ...] <input type> <input> [<output path>]

ARGUMENTS:
  <input type>                          The type of input used in the <input> argument
  <input>                               The input used to build the QR code's data. For input
                                        type "text" specify a string, for "bytes" and
                                        "textFile" a file path or "-" for stdin
  <output path>                         Directory or file path where to write output files to
                                        (default: directory of input file or working directory)

GENERATOR OPTIONS:
  -l, --level (L | M | Q | H)           The QR code's correction level (parity) (default: M)
  --min <version 1-40>                  Minimum QR code version (i.e. size) to use. Not
                                        supported with "--coreimage" flag (default: 1)
  --max <version 1-40>                  Maximum QR code version (i.e. size) to use. Error is
                                        thrown if the supplied input and correction level would
                                        produce a larger QR code (default: 40)
  -o, --optimize                        Try to reduce length of QR code data by splitting text
                                        input into segments of different encodings. Not
                                        supported with "--coreimage" flag.
  --strict                              Strictly conform to the QR code specification when
                                        encoding text. Might increase length of QR code data.
                                        No effect with "--coreimage" flag.

STYLE OPTIONS:
  -s, --style (standard | dots | holes | liquidDots | liquidHoles)
                                        The QR code's style (default: standard)
  -m, --pixel-margin <percentage>       Shrink the QR code's individual pixels by the specified
                                        percentage. Values >50 may produce unreadable results
                                        (default: 0)
  -r, --corner-radius <percentage>      Specify corner radius as a percentage of half pixel
                                        size. Ignored for "standard" style (default: 100)
  -a, --style-all                       Apply styling to all pixels, including the QR code's
                                        position markers

GENERAL OPTIONS:
  -p, --png                             Additionally to the SVG output file, also create an
                                        unstyled PNG file
  --coreimage                           Use built-in "CIQRCodeGenerator" filter from CoreImage
                                        to generate QR code instead of Nayuki implementation
  -h, --help                            Show help information.
```
