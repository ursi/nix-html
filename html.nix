with builtins;
l:
  let
    make-attributes = attributes:
      let to-escaped-string = s: replaceStrings [ "\"" ] [ "&quot;" ] (toString s); in
      if isAttrs attributes then
        toString
          (l.mapAttrsToList
             (n: v:
               if isBool v then
                 if v then n else ""
               else if n == "style" && isAttrs v then
                 let
                   styles =
                     to-escaped-string
                       (l.mapAttrsToList
                          (n': v': "${n'}: ${toString v'};")
                          v
                       );
                 in
                 ''style="${styles}"''
               else
                 ''${n}="${to-escaped-string v}"''
             )
             attributes
          )
      else
        let str = toString attributes; in
        if str == "" then ""
        else ''class="${to-escaped-string str}"'';

    args =
      l.mapAttrs
        (name: description: { inherit name description; })
        { name = "the name of the HTML elment";
          attributes = "If `attributes` is an attrset, the keys will be added with the `toString` of their values as attributes to the element. If `attributes` is not an attrset, it will be `toString`'d and the resulting string will be used as a `class` attribute.";
          children = "`toString children` will be the text inside the element.";
        };

    element =
      { args =
          [ args.name
            args.attributes
            args.children
          ];

        returns = "An HTML `name` element";
        notes = "All non-self-closing, non-`html` HTML elements, e.g. `div`, have their own function which is just this function with `name` supplied.";
        examples =
          [ ''element "div" "thing" "inner text" == '''<div class="thing">inner text</div>'''''
            ''div "thing" "inner text" == '''<div class="thing">inner text</div>'''''
          ];

        __functor = _: name: attributes: children:
          let
            children-str =
              if l.strings.isCoercibleToString children then
                toString children
              else
                abort
                  ''
                  "toString children" failed. Here is some info:
                  name:            ${name}
                  attributes:      ${toString attributes}
                  typeOf children: ${typeOf children}
                  '';
          in
          "<${name} ${make-attributes attributes}>${children-str}</${name}>";
      };

    element-for-documentation = name:
      { args = [ args.attributes args.children ];
        returns = "An HTML `${name}` element";
        examples = [ ''${name} "thing" "inner text" == '''<${name} class="thing">inner text</${name}>''''' ];
        __functor = _: element name;
      };

    self-closing =
      { args =
          [ args.name
            args.attributes
          ];

        returns = "A self-closing HTML `name` element";
        notes = "All self-closing HTML elements, e.g. `img`, have their own function which is just this function with `name` supplied.";

        examples =
          [ ''self-closing "img" { src = "image.com/image"; } == '''<img src="image.com/image">'''''
            ''img { src = "image.com/image"; } == '''<img src="image.com/image">'''''
          ];

        __functor = _: name: attributes:
          "<${name} ${make-attributes attributes}>";
      };

    self-closing-for-documentation = name:
      { args = [ args.attributes args.children ];
        returns = "An HTML `${name}` element";
        examples = [ ''${name} "thing" == '''<${name} class="thing">''''' ];
        __functor = _: self-closing-for-documentation name;
      };
  in
  { inherit element self-closing;

    escape =
      { args = [ { name = "string"; description = "a string"; } ];
        returns = "`string` with HTML special characters escaped";
        examples = [ ''escape "<div>&escaped</div>" == "&lt;div&gt;&amp;escaped&lt;/div&gt;"'' ];
        section = "test";
        __functor = _: replaceStrings [ "<" ">" "&" ] [ "&lt;" "&gt;" "&amp;" ];
      };

    html =
      { args = [ args.attributes args.children ];
        returns = "An `html` doctype and an HTML `html` element";

        examples =
          [ ''
            html "<head></head><body></body>"
            == <!DOCTYPE html><html><head></head><body></body></html>
            ''
          ];

        __functor = _: a: c: "<!DOCTYPE html>" + element "html" a c;
      };
  }
  // (listToAttrs
        (map (n: l.nameValuePair n (element n))
           [ "a"
             "abbr"
             "address"
             "article"
             "aside"
             "audio"
             "b"
             "bdi"
             "bdo"
             "blockquote"
             "body"
             "button"
             "canvas"
             "caption"
             "cite"
             "code"
             "colgroup"
             "data"
             "datalist"
             "dd"
             "del"
             "details"
             "dfn"
             "dialog"
             "div"
             "dl"
             "dt"
             "em"
             "fieldset"
             "figcaption"
             "figure"
             "footer"
             "form"
             "h1" "h2" "h3" "h4" "h5" "h6"
             "head"
             "header"
             "hgroup"
             "i"
             "iframe"
             "ins"
             "kbd"
             "label"
             "legend"
             "li"
             "main"
             "mark"
             "math"
             "menu"
             "meter"
             "nav"
             "noscript"
             "object"
             "ol"
             "optgroup"
             "option"
             "output"
             "p"
             "picture"
             "pre"
             "progress"
             "q"
             "rp"
             "rt"
             "ruby"
             "s"
             "samp"
             "script"
             "section"
             "select"
             "slot"
             "small"
             "span"
             "strong"
             "style"
             "sub"
             "summary"
             "sup"
             "svg"
             "table"
             "tbody"
             "td"
             "textarea"
             "tfoot"
             "th"
             "thead"
             "time"
             "title"
             "tr"
             "u"
             "ul"
             "var"
             "video"
           ]
        )
     )
  // (listToAttrs
        (map (n: l.nameValuePair n (self-closing n))
           [ "area"
             "base"
             "br"
             "col"
             "embed"
             "hr"
             "img"
             "input"
             "link"
             "meta"
             "param"
             "source"
             "template"
             "track"
             "wbr"
           ]
        )
     )
