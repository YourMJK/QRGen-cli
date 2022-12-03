# QRGen
Swift CLI tool to generate stylized QR codes (SVG and PNG) from data or text

## Usage

```
USAGE: QRGen [OPTIONS ...] <input type> <input> [<output path>]

ARGUMENTS:
  <input type>                          The type of input used in the <input> argument (values:
                                        text | textFile | bytes)
  <input>                               The input used to build the QR code's data. For input
                                        type "text" specify a string, for "textFile" and
                                        "bytes" a file path or "-" for stdin
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
  --no-shape-optimization               Add one shape per pixel to the SVG instead of combining
                                        touching shapes. This may result in anti-aliasing
                                        artifacts (thin lines) between neighboring pixels when
                                        viewing the SVG!
  -h, --help                            Show help information.

EXAMPLES:
  QRGen text "http://example.org" example
  QRGen -l Q textFile data.txt
  QRGen --level L -s liquidDots -r 80 -a bytes event.ics
```

## How to build

* **Variant 1**:  
Run `make` to build the Swift Package.
* **Variant 2**:  
Open the Xcode project and go to *Product > Build (⌘B)*.

After using one of these two variants to build the binary, you can either run it directly from `build/QRGen` or install it to your PATH location, e.g.:  
`$ cp build/QRGen /usr/local/bin/`
