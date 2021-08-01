with builtins;
let
  l = pkgs.lib;
  inherit (import ./inputs.nix) pkgs;

  make-attributes = attributes:
    if isAttrs attributes then
      toString
        (l.mapAttrsToList
           (n: v:
             if isBool v then if v then n else ""
             else ''${n}="${toString v}"''
           )
           attributes
        )
    else
      let str = toString attributes; in
      if str == "" then ""
      else ''class="${str}"'';

  element = name: attributes: children:
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

  self-closing = name: attributes:
    "<${name} ${make-attributes attributes}>";
in
{ inherit element self-closing;
  html = a: c: "<!DOCTYPE html>" + element "html" a c;
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
